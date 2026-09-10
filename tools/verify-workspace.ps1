[CmdletBinding()]
param(
    [string]$Root,
    [ValidateSet('precommit', 'postcommit')]
    [string]$Phase = 'postcommit'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$nextActionId = $null
$nextActionKind = $null
$nextActionWorkflow = $null
$nextActionInputPaths = @()
$activeId = $null
$dispatchState = $null
$sourceMemlog = $null
$sourceContract = $null
$implementationContract = $null
$lastHandoff = $null
$migrationState = $null
$requiresRemote = $false
$requiresInstalledRuntime = $false
$isOperational = $false
$handoffMarker = $null
$handoffRelativePath = $null
$continuityMethod = $null
$continuityRemoteName = $null
$continuityEvidencePath = $null

function Add-CheckError([string]$Message) {
    $errors.Add($Message)
}

function Add-CheckWarning([string]$Message) {
    $warnings.Add($Message)
}

try {
    $script:rootPath = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
}
catch {
    Write-Error "Cannot open workspace root: $Root"
    exit 2
}

$script:rootCompare = $script:rootPath.TrimEnd('\', '/')
$script:rootPrefix = $script:rootCompare + [System.IO.Path]::DirectorySeparatorChar

function Test-IsInsideRoot([string]$FullPath, [string]$Label) {
    $inside = ($FullPath -eq $script:rootCompare) -or $FullPath.StartsWith($script:rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $inside) {
        Add-CheckError("$Label escapes the workspace root: $FullPath")
        return $false
    }
    return $true
}

function Resolve-WorkspacePath([string]$RawPath, [string]$Label, [bool]$RequireExists) {
    $value = $RawPath.Trim().Trim('"').Trim("'")
    if ([string]::IsNullOrWhiteSpace($value) -or $value -eq 'null') {
        return $null
    }
    if ([System.IO.Path]::IsPathRooted($value) -or $value -match '^[A-Za-z]:' -or $value -match '(^|[\\/])\.\.([\\/]|$)') {
        Add-CheckError("$Label must be a safe repository-relative path: $value")
        return $null
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath((Join-Path $script:rootPath $value))
    }
    catch {
        Add-CheckError("$Label is not a valid path: $value")
        return $null
    }

    if (-not (Test-IsInsideRoot $fullPath $Label)) {
        return $null
    }
    if ($RequireExists -and -not (Test-Path -LiteralPath $fullPath)) {
        Add-CheckError("$Label does not exist: $value")
        return $null
    }
    if (Test-Path -LiteralPath $fullPath) {
        try {
            $resolved = (Resolve-Path -LiteralPath $fullPath -ErrorAction Stop).Path
            if (-not (Test-IsInsideRoot $resolved $Label)) {
                return $null
            }
            return $resolved
        }
        catch {
            Add-CheckError("$Label cannot be resolved: $value")
            return $null
        }
    }
    return $fullPath
}

function Test-RequiredFile([string]$RelativePath) {
    $target = Resolve-WorkspacePath $RelativePath 'Required file' $true
    if ($null -eq $target -or -not (Test-Path -LiteralPath $target -PathType Leaf)) {
        if ($null -ne $target) {
            Add-CheckError("Required file is missing: $RelativePath")
        }
        return $false
    }
    return $true
}

function Get-YamlRootBlock([string]$Text, [string]$Key) {
    $pattern = '(?ms)^' + [regex]::Escape($Key) + ':\s*\r?\n(?<block>.*?)(?=^[^\s]|\z)'
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) {
        return $match.Groups['block'].Value
    }
    return $null
}

function Get-YamlScalar([string]$Block, [string]$Key) {
    if ($null -eq $Block) {
        return $null
    }
    $pattern = '(?m)^\s{2}' + [regex]::Escape($Key) + ':\s*(?<value>[^#\r\n]+)'
    $match = [regex]::Match($Block, $pattern)
    if ($match.Success) {
        return $match.Groups['value'].Value.Trim().Trim('"').Trim("'")
    }
    return $null
}

function Test-TomlModuleEnabled([string]$Toml, [string]$Module) {
    $pattern = '(?ms)^\[modules\.' + [regex]::Escape($Module) + '\]\s*\r?\n(?<block>.*?)(?=^\[|\z)'
    $section = [regex]::Match($Toml, $pattern)
    if (-not $section.Success) {
        return $false
    }
    return -not [regex]::IsMatch($section.Groups['block'].Value, '(?im)^\s*enabled\s*=\s*false\s*(?:#.*)?$')
}

$requiredFiles = @(
    'AGENTS.md',
    'README.md',
    'control/NOW.yaml',
    'control/WORKSPACE-PROFILE.yaml',
    'control/ROUTING.md',
    'control/STATE-MACHINE.md',
    'control/START-NEW-CHAT.md',
    'docs/PROJECT-CHARTER.md',
    'handoffs/README.md',
    'handoffs/TEMPLATE.md',
    'templates/INIT-001.md'
)

foreach ($relativePath in $requiredFiles) {
    [void](Test-RequiredFile $relativePath)
}

$nowPath = Join-Path $script:rootPath 'control/NOW.yaml'
$profilePath = Join-Path $script:rootPath 'control/WORKSPACE-PROFILE.yaml'
$charterPath = Join-Path $script:rootPath 'docs/PROJECT-CHARTER.md'

if ((Test-Path -LiteralPath $nowPath -PathType Leaf) -and (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    $now = Get-Content -LiteralPath $nowPath -Raw
    $profile = Get-Content -LiteralPath $profilePath -Raw
    $activeBlock = Get-YamlRootBlock $now 'active_work'
    $activeId = Get-YamlScalar $activeBlock 'id'
    if ([string]::IsNullOrWhiteSpace($activeId)) {
        Add-CheckError('NOW.yaml is missing active_work.id.')
    }
    $handoffMatch = [regex]::Match($now, '(?m)^last_handoff:\s*(?<value>[^#\r\n]+)')
    if (-not $handoffMatch.Success) {
        Add-CheckError('NOW.yaml is missing last_handoff.')
    }
    else {
        $lastHandoff = $handoffMatch.Groups['value'].Value.Trim().Trim('"').Trim("'")
    }
    $dispatchState = Get-YamlScalar $activeBlock 'dispatch_state'
    if ($dispatchState -notin @('setup', 'planning', 'implementation', 'verification', 'blocked', 'closed')) {
        Add-CheckError("Unknown or missing active_work.dispatch_state: $dispatchState")
    }
    $migrationBlock = Get-YamlRootBlock $profile 'migration'
    $migrationState = Get-YamlScalar $migrationBlock 'state'
    if ($migrationState -notin @('remote-pending', 'runtime-pending', 'restore-pending', 'ready')) {
        Add-CheckError("Unknown or missing migration.state: $migrationState")
    }
    $requiresRemote = $migrationState -in @('runtime-pending', 'restore-pending', 'ready')
    $requiresInstalledRuntime = $migrationState -in @('restore-pending', 'ready')
    $isOperational = $migrationState -eq 'ready'
    if ($isOperational -and $activeId -eq 'INIT-001') {
        Add-CheckError('migration.state is ready but active_work.id was not replaced with a real work-item ID.')
    }

    $nextMatches = [regex]::Matches($now, '(?m)^next_action:\s*$')
    if ($nextMatches.Count -ne 1) {
        Add-CheckError("NOW.yaml must contain exactly one next_action block; found: $($nextMatches.Count).")
    }
    else {
        $nextBlock = Get-YamlRootBlock $now 'next_action'
        if ($null -eq $nextBlock) {
            Add-CheckError('Cannot parse next_action block in NOW.yaml.')
        }
        else {
            $nextActionId = Get-YamlScalar $nextBlock 'id'
            $nextActionKind = Get-YamlScalar $nextBlock 'kind'
            $nextActionWorkflow = Get-YamlScalar $nextBlock 'workflow'
            $requiredFields = @('id', 'kind', 'title', 'input_paths', 'expected_outputs', 'done_when', 'forbidden_scope')
            foreach ($field in $requiredFields) {
                $pattern = '(?m)^\s{2}' + [regex]::Escape($field) + ':\s*\S*'
                if (-not [regex]::IsMatch($nextBlock, $pattern)) {
                    Add-CheckError("Required next_action field is missing: $field")
                }
            }

            foreach ($field in @('id', 'kind', 'title')) {
                $value = Get-YamlScalar $nextBlock $field
                if ([string]::IsNullOrWhiteSpace($value) -or $value -eq 'null') {
                    Add-CheckError("next_action.$field must be a non-empty scalar value.")
                }
            }
            if ($nextActionKind -notin @('decision', 'bmad-workflow', 'implementation', 'verification', 'ask-owner')) {
                Add-CheckError("Unknown or missing next_action.kind: $nextActionKind")
            }
            if ($nextActionKind -eq 'bmad-workflow' -and ([string]::IsNullOrWhiteSpace($nextActionWorkflow) -or $nextActionWorkflow -eq 'null')) {
                Add-CheckError('next_action.kind bmad-workflow requires a concrete next_action.workflow.')
            }

            $listFields = @('input_paths', 'expected_outputs', 'done_when', 'forbidden_scope')
            foreach ($field in $listFields) {
                $listPattern = '(?ms)^\s{2}' + [regex]::Escape($field) + ':\s*\r?\n(?<items>(?:\s{4}-\s*[^\r\n]+\r?\n?)+)'
                $listMatch = [regex]::Match($nextBlock, $listPattern)
                if (-not $listMatch.Success) {
                    Add-CheckError("next_action.$field must contain at least one list item.")
                    continue
                }
                $items = [regex]::Matches($listMatch.Groups['items'].Value, '(?m)^\s*-\s*(?<value>[^\r\n]+)')
                foreach ($item in $items) {
                    $itemValue = $item.Groups['value'].Value.Trim().Trim('"').Trim("'")
                    if ([string]::IsNullOrWhiteSpace($itemValue) -or $itemValue -eq 'null') {
                        Add-CheckError("next_action.$field must not contain an empty or null list item.")
                        continue
                    }
                    if ($field -eq 'input_paths') {
                        $nextActionInputPaths += $itemValue.Replace('\\', '/')
                        [void](Resolve-WorkspacePath $itemValue 'next_action.input_paths' $true)
                    }
                }
            }
        }
    }

    $blocker = Get-YamlScalar $activeBlock 'blocker'
    $resumeState = Get-YamlScalar $activeBlock 'resume_state'
    if ($dispatchState -eq 'blocked') {
        if ($nextActionKind -ne 'ask-owner') {
            Add-CheckError('blocked dispatch_state requires next_action.kind: ask-owner.')
        }
        if ([string]::IsNullOrWhiteSpace($blocker) -or $blocker -eq 'null') {
            Add-CheckError('blocked dispatch_state requires an active_work.blocker.')
        }
        if ($resumeState -notin @('setup', 'planning', 'implementation', 'verification')) {
            Add-CheckError('blocked dispatch_state requires active_work.resume_state.')
        }
    }
    elseif ($nextActionKind -eq 'ask-owner') {
        Add-CheckError('next_action.kind: ask-owner requires dispatch_state: blocked.')
    }
    else {
        if (-not [string]::IsNullOrWhiteSpace($blocker) -and $blocker -ne 'null') {
            Add-CheckError('A non-blocked work item must not keep an active_work.blocker.')
        }
        if (-not [string]::IsNullOrWhiteSpace($resumeState) -and $resumeState -ne 'null') {
            Add-CheckError('A non-blocked work item must not keep an active_work.resume_state.')
        }
    }

    $bmadBlock = Get-YamlRootBlock $profile 'bmad_install'
    $deliveryBlock = Get-YamlRootBlock $profile 'delivery'
    $continuityBlock = Get-YamlRootBlock $profile 'continuity'
    $continuityMethod = Get-YamlScalar $continuityBlock 'method'
    $continuityRemoteName = Get-YamlScalar $continuityBlock 'remote_name'
    $continuityEvidencePath = Get-YamlScalar $continuityBlock 'evidence_path'
    $lane = Get-YamlScalar $deliveryBlock 'lane'
    if ($lane -notin @('change', 'bmm-project')) {
        Add-CheckError("Unknown or unsupported delivery lane: $lane")
    }

    $moduleBlockMatch = if ($null -ne $bmadBlock) { [regex]::Match($bmadBlock, '(?ms)^\s{2}enabled_modules:\s*\r?\n(?<items>(?:\s{4}-\s*[^\r\n]+\r?\n?)+)') } else { $null }
    $modules = @()
    if (($null -eq $moduleBlockMatch) -or (-not $moduleBlockMatch.Success)) {
        Add-CheckError('WORKSPACE-PROFILE.yaml requires a multiline bmad_install.enabled_modules list.')
    }
    else {
        $modules = @([regex]::Matches($moduleBlockMatch.Groups['items'].Value, '(?m)^\s*-\s*(?<module>[^#\r\n]+)') | ForEach-Object { $_.Groups['module'].Value.Trim().Trim('"').Trim("'").ToLowerInvariant() })
        if ($modules -notcontains 'core') {
            Add-CheckError('enabled_modules does not contain core.')
        }
        if ($modules -notcontains 'bmm') {
            Add-CheckError('Core+BMM template requires bmm.')
        }
        if ($modules -contains 'gds') {
            Add-CheckError('Core+BMM template must not install GDS as a second delivery module.')
        }
    }

    $pointerFields = @('source_memlog', 'source_contract', 'implementation_contract', 'queue_path')
    foreach ($pointer in $pointerFields) {
        $pointerValue = Get-YamlScalar $activeBlock $pointer
        if ($null -ne $pointerValue -and $pointerValue -ne 'null') {
            [void](Resolve-WorkspacePath $pointerValue "active_work.$pointer" $true)
        }
    }
    $queuePath = Get-YamlScalar $activeBlock 'queue_path'
    $selectedStoryId = Get-YamlScalar $activeBlock 'selected_story_id'
    $sourceMemlog = Get-YamlScalar $activeBlock 'source_memlog'
    $sourceContract = Get-YamlScalar $activeBlock 'source_contract'
    $implementationContract = Get-YamlScalar $activeBlock 'implementation_contract'
    if ($sourceContract -ne 'null' -and -not [string]::IsNullOrWhiteSpace($sourceContract) -and ($sourceMemlog -eq 'null' -or [string]::IsNullOrWhiteSpace($sourceMemlog))) {
        Add-CheckError('active_work.source_contract requires active_work.source_memlog as its decision record.')
    }
    if ($nextActionWorkflow -eq 'bmad-build' -and ([string]::IsNullOrWhiteSpace($sourceContract) -or $sourceContract -eq 'null')) {
        Add-CheckError('A bmad-build action requires active_work.source_contract.')
    }
    if ($nextActionKind -eq 'implementation' -and ([string]::IsNullOrWhiteSpace($implementationContract) -or $implementationContract -eq 'null')) {
        Add-CheckError('An implementation action requires active_work.implementation_contract.')
    }
    if ($nextActionKind -eq 'implementation' -and ([string]::IsNullOrWhiteSpace($sourceContract) -or $sourceContract -eq 'null')) {
        Add-CheckError('An implementation action requires active_work.source_contract.')
    }
    if ($nextActionWorkflow -eq 'bmad-build' -and $sourceContract -ne 'null' -and -not [string]::IsNullOrWhiteSpace($sourceContract) -and $nextActionInputPaths -notcontains $sourceContract.Replace('\\', '/')) {
        Add-CheckError('A bmad-build action must list active_work.source_contract in next_action.input_paths.')
    }
    if ($nextActionKind -eq 'implementation' -and $implementationContract -ne 'null' -and -not [string]::IsNullOrWhiteSpace($implementationContract) -and $nextActionInputPaths -notcontains $implementationContract.Replace('\\', '/')) {
        Add-CheckError('An implementation action must list active_work.implementation_contract in next_action.input_paths.')
    }
    if ($implementationContract -ne 'null' -and -not [string]::IsNullOrWhiteSpace($implementationContract)) {
        if ($sourceContract -eq 'null' -or [string]::IsNullOrWhiteSpace($sourceContract)) {
            Add-CheckError('active_work.implementation_contract requires active_work.source_contract.')
        }
        else {
            $implementationPath = Resolve-WorkspacePath $implementationContract 'active_work.implementation_contract' $true
            if ($null -ne $implementationPath -and (Test-Path -LiteralPath $implementationPath -PathType Leaf)) {
                $implementationText = Get-Content -LiteralPath $implementationPath -Raw
                $sourceReferencePattern = '(?m)^\s*source_contract\s*:\s*["' + "'" + ']?' + [regex]::Escape($sourceContract) + '["' + "'" + ']?\s*(?:#.*)?$'
                if (-not [regex]::IsMatch($implementationText, $sourceReferencePattern)) {
                    Add-CheckError('The implementation contract does not contain a matching source_contract pointer.')
                }
            }
        }
    }
    if ($lane -eq 'change' -and $queuePath -ne 'null' -and -not [string]::IsNullOrWhiteSpace($queuePath)) {
        Add-CheckError('change lane must not set active_work.queue_path.')
    }
    if ($queuePath -ne 'null' -and -not [string]::IsNullOrWhiteSpace($queuePath) -and ($selectedStoryId -eq 'null' -or [string]::IsNullOrWhiteSpace($selectedStoryId))) {
        Add-CheckError('active_work.queue_path requires active_work.selected_story_id.')
    }
    if (($queuePath -eq 'null' -or [string]::IsNullOrWhiteSpace($queuePath)) -and $selectedStoryId -ne 'null' -and -not [string]::IsNullOrWhiteSpace($selectedStoryId)) {
        Add-CheckError('active_work.selected_story_id requires active_work.queue_path.')
    }

    if ($isOperational) {
        if ($profile -match '<project-id>|<project-name>') {
            Add-CheckError('An operational workspace still has project placeholders in the profile.')
        }
        if ((Test-Path -LiteralPath $charterPath -PathType Leaf) -and ((Get-Content -LiteralPath $charterPath -Raw) -match '<[^>]+>')) {
            Add-CheckError('An operational workspace still has unfilled placeholders in PROJECT-CHARTER.md.')
        }

        $installedVersion = Get-YamlScalar $bmadBlock 'installed_version'
        if ([string]::IsNullOrWhiteSpace($installedVersion) -or $installedVersion -eq 'null') {
            Add-CheckError('An operational workspace must record bmad_install.installed_version.')
        }

        $continuityMethod = Get-YamlScalar $continuityBlock 'method'
        if ($continuityMethod -ne 'git-remote') {
            Add-CheckError("Unknown or missing continuity.method: $continuityMethod")
        }
        else {
            $continuityRemoteName = Get-YamlScalar $continuityBlock 'remote_name'
            if ([string]::IsNullOrWhiteSpace($continuityRemoteName) -or $continuityRemoteName -eq 'null') {
                Add-CheckError('continuity.method git-remote requires continuity.remote_name.')
            }
        }

        $continuityEvidencePath = Get-YamlScalar $continuityBlock 'evidence_path'
        if ([string]::IsNullOrWhiteSpace($continuityEvidencePath) -or $continuityEvidencePath -eq 'null') {
            Add-CheckError('An operational workspace requires continuity.evidence_path from a successful restore test.')
        }
        else {
            $continuityEvidence = Resolve-WorkspacePath $continuityEvidencePath 'continuity.evidence_path' $true
            if ($null -ne $continuityEvidence -and (Test-Path -LiteralPath $continuityEvidence -PathType Leaf)) {
                $continuityEvidenceText = Get-Content -LiteralPath $continuityEvidence -Raw
                if ($continuityEvidenceText -match '<[^>]+>') {
                    Add-CheckError('continuity.evidence_path still contains unfilled placeholders.')
                }
                if (-not [regex]::IsMatch($continuityEvidenceText, '(?im)^\s*-\s+\*\*Result:\*\*\s*`?pass`?\s*$')) {
                    Add-CheckError('continuity.evidence_path must record a successful restore result.')
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($lastHandoff) -or $lastHandoff -eq 'null') {
            Add-CheckError('An operational workspace must set NOW.last_handoff.')
        }
        else {
            $handoffPath = Resolve-WorkspacePath $lastHandoff 'NOW.last_handoff' $true
            if ($null -ne $handoffPath -and (Test-Path -LiteralPath $handoffPath -PathType Leaf)) {
                $handoffRelativePath = $lastHandoff.Replace('\', '/')
                if (-not $handoffRelativePath.StartsWith('handoffs/', [System.StringComparison]::OrdinalIgnoreCase) -or $handoffRelativePath -eq 'handoffs/TEMPLATE.md') {
                    Add-CheckError('NOW.last_handoff must point to a concrete file under handoffs/, not its template.')
                }
                $handoffText = Get-Content -LiteralPath $handoffPath -Raw
                if ($handoffText -match '<[^>]+>') {
                    Add-CheckError('The last handoff still contains unfilled placeholders.')
                }
                if (-not [string]::IsNullOrWhiteSpace($nextActionId)) {
                    $expectedIdPattern = '(?m)^-\s+\*\*ID:\*\*\s*' + [regex]::Escape($nextActionId) + '\s*$'
                    if (-not [regex]::IsMatch($handoffText, $expectedIdPattern)) {
                        Add-CheckError('The last handoff does not name the same next_action.id as NOW.yaml.')
                    }
                }
                $markerMatch = [regex]::Match($handoffText, '(?m)^-\s+\*\*Commit marker:\*\*\s*(?<marker>[^\r\n]+)')
                if (-not $markerMatch.Success -or $markerMatch.Groups['marker'].Value.Trim() -match '^<') {
                    Add-CheckError('The last handoff is missing a concrete Commit marker.')
                }
                else {
                    $handoffMarker = $markerMatch.Groups['marker'].Value.Trim().Trim('`').Trim('"').Trim("'")
                }
            }
        }
    }

    if (-not $isOperational -and -not [string]::IsNullOrWhiteSpace($lastHandoff) -and $lastHandoff -ne 'null') {
        $handoffPath = Resolve-WorkspacePath $lastHandoff 'NOW.last_handoff' $true
        if ($null -ne $handoffPath -and (Test-Path -LiteralPath $handoffPath -PathType Leaf)) {
            $handoffRelativePath = $lastHandoff.Replace('\', '/')
            if (-not $handoffRelativePath.StartsWith('handoffs/', [System.StringComparison]::OrdinalIgnoreCase) -or $handoffRelativePath -eq 'handoffs/TEMPLATE.md') {
                Add-CheckError('NOW.last_handoff must point to a concrete file under handoffs/, not its template.')
            }
            $handoffText = Get-Content -LiteralPath $handoffPath -Raw
            if ($handoffText -match '<[^>]+>') {
                Add-CheckError('The last handoff still contains unfilled placeholders.')
            }
            if (-not [string]::IsNullOrWhiteSpace($nextActionId)) {
                $expectedIdPattern = '(?m)^-\s+\*\*ID:\*\*\s*' + [regex]::Escape($nextActionId) + '\s*$'
                if (-not [regex]::IsMatch($handoffText, $expectedIdPattern)) {
                    Add-CheckError('The last handoff does not name the same next_action.id as NOW.yaml.')
                }
            }
            $markerMatch = [regex]::Match($handoffText, '(?m)^-\s+\*\*Commit marker:\*\*\s*(?<marker>[^\r\n]+)')
            if (-not $markerMatch.Success -or $markerMatch.Groups['marker'].Value.Trim() -match '^<') {
                Add-CheckError('The last handoff is missing a concrete Commit marker.')
            }
            else {
                $handoffMarker = $markerMatch.Groups['marker'].Value.Trim().Trim('`').Trim('"').Trim("'")
            }
        }
    }

    if ($requiresRemote) {
        if ($continuityMethod -ne 'git-remote') {
            Add-CheckError("Unknown or missing continuity.method: $continuityMethod")
        }
        elseif ([string]::IsNullOrWhiteSpace($continuityRemoteName) -or $continuityRemoteName -eq 'null') {
            Add-CheckError('continuity.method git-remote requires continuity.remote_name.')
        }
    }

    if ($requiresInstalledRuntime) {
        $installedVersion = Get-YamlScalar $bmadBlock 'installed_version'
        if ([string]::IsNullOrWhiteSpace($installedVersion) -or $installedVersion -eq 'null') {
            Add-CheckError('A restore-pending or ready workspace must record bmad_install.installed_version.')
        }
    }

    $installedConfig = Join-Path $script:rootPath '_bmad/config.toml'
    if ($requiresInstalledRuntime -and -not (Test-Path -LiteralPath $installedConfig -PathType Leaf)) {
        Add-CheckError('A restore-pending or ready workspace requires installed _bmad/config.toml.')
    }
    elseif (Test-Path -LiteralPath $installedConfig -PathType Leaf) {
        $installedText = Get-Content -LiteralPath $installedConfig -Raw
        if ($requiresInstalledRuntime -and -not [regex]::IsMatch($installedText, '(?m)^\[core\]')) {
            Add-CheckError('Installed _bmad/config.toml is missing the core section.')
        }
        if ($requiresInstalledRuntime -and -not (Test-TomlModuleEnabled $installedText 'bmm')) {
            Add-CheckError('Installed _bmad/config.toml does not enable BMM.')
        }
        if (Test-TomlModuleEnabled $installedText 'gds') {
            Add-CheckError('Installed _bmad/config.toml enables GDS in a Core+BMM workspace.')
        }
    }
}

$gitDirectory = Join-Path $script:rootPath '.git'
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ((Test-Path -LiteralPath $gitDirectory) -and $null -ne $gitCommand) {
    $status = @(& git -C $script:rootPath status --porcelain 2>$null)
    if ($status.Count -gt 0) {
        if ($isOperational -and $Phase -eq 'postcommit') {
            Add-CheckError('postcommit validation requires a clean Git working tree.')
        }
        else {
            Add-CheckWarning('Git working tree is not clean. Commit changes before postcommit validation.')
        }
    }

    $trackedLocal = @(& git -C $script:rootPath ls-files 2>$null | Where-Object {
        $leaf = Split-Path $_ -Leaf
        ($leaf -eq '.env') -or (($leaf -like '.env.*') -and ($leaf -ne '.env.example')) -or ($leaf -match '\.local\.(json|yaml|yml|toml)$')
    })
    if ($trackedLocal.Count -gt 0) {
        Add-CheckError("Git versions machine-local/secret-like files: $($trackedLocal -join ', ')")
    }

    $profileText = if (Test-Path -LiteralPath $profilePath -PathType Leaf) { Get-Content -LiteralPath $profilePath -Raw } else { $null }
    $profileInstallBlock = Get-YamlRootBlock $profileText 'bmad_install'
    $installMode = Get-YamlScalar $profileInstallBlock 'mode'
    if ($installMode -ne 'bootstrap-per-clone') {
        Add-CheckError('This minimal template supports only bmad_install.mode: bootstrap-per-clone.')
    }
    else {
        $trackedRuntime = @(& git -C $script:rootPath ls-files 2>$null | Where-Object { $_ -match '^(_bmad|\.agents)/' })
        if ($trackedRuntime.Count -gt 0) {
            if ($migrationState -eq 'remote-pending') {
                Add-CheckWarning('Legacy installer-managed _bmad/ or .agents/ remain versioned during remote-pending bootstrap.')
            }
            else {
                Add-CheckError('bootstrap-per-clone mode versions installer-managed _bmad/ or .agents/.')
            }
        }
    }

    if ($requiresRemote -and $continuityMethod -eq 'git-remote' -and -not [string]::IsNullOrWhiteSpace($continuityRemoteName)) {
        $remoteUrl = @(& git -C $script:rootPath remote get-url $continuityRemoteName 2>$null)
        if ($remoteUrl.Count -eq 0) {
            Add-CheckError("Configured continuity remote is unavailable: $continuityRemoteName")
        }
        elseif ($isOperational -and $Phase -eq 'postcommit') {
            $headRevision = @(& git -C $script:rootPath rev-parse HEAD 2>$null) -join ''
            $currentBranch = @(& git -C $script:rootPath branch --show-current 2>$null) -join ''
            if ([string]::IsNullOrWhiteSpace($currentBranch)) {
                Add-CheckError('Cannot determine the current branch. Postcommit validation requires a named branch that is pushed to the continuity remote.')
            }
            elseif (-not [string]::IsNullOrWhiteSpace($headRevision)) {
                $expectedRemoteRef = "refs/heads/$currentBranch"
                $remoteBranchRefs = @(& git -C $script:rootPath ls-remote --heads $continuityRemoteName $expectedRemoteRef 2>$null)
                $headOnCurrentRemoteBranch = [regex]::IsMatch(
                    ($remoteBranchRefs -join "`n"),
                    '(?m)^' + [regex]::Escape($headRevision) + '\s+' + [regex]::Escape($expectedRemoteRef) + '$'
                )
                if (-not $headOnCurrentRemoteBranch) {
                    Add-CheckError("The continuity remote branch $expectedRemoteRef does not contain the current HEAD. Push the handoff commit to the current branch before postcommit validation.")
                }
            }
            else {
                Add-CheckError('Cannot determine the current HEAD for postcommit validation.')
            }
        }
    }

    if ($null -ne $handoffMarker -and $Phase -eq 'postcommit') {
        $headMessage = @(& git -C $script:rootPath log -1 --format=%B HEAD 2>$null) -join "`n"
        if (-not [regex]::IsMatch($headMessage, [regex]::Escape($handoffMarker))) {
            Add-CheckError('The current HEAD commit does not contain the marker declared by NOW.last_handoff.')
        }
        else {
            $commitFiles = @(& git -C $script:rootPath show --format= --name-only HEAD 2>$null)
            if ($commitFiles -notcontains $handoffRelativePath) {
                Add-CheckError('The current HEAD handoff commit does not include the declared handoff file.')
            }
            if ($commitFiles -notcontains 'control/NOW.yaml') {
                Add-CheckError('The current HEAD handoff commit does not include control/NOW.yaml.')
            }
        }
    }
}
elseif ($isOperational) {
    Add-CheckError('An operational workspace requires a Git repository and Git command for handoff validation.')
}
elseif (-not (Test-Path -LiteralPath $gitDirectory)) {
    Add-CheckWarning('No Git repository yet. Create one before the first handoff.')
}
else {
    Add-CheckWarning('Git is unavailable; version-control checks were skipped.')
}

if ($warnings.Count -gt 0) {
    foreach ($warning in $warnings) {
        Write-Host "WARNING: $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Host "ERROR: $errorMessage" -ForegroundColor Red
    }
    Write-Host "Validation failed: $($errors.Count) error(s), $($warnings.Count) warning(s)." -ForegroundColor Red
    exit 1
}

Write-Host "Validation passed: 0 errors, $($warnings.Count) warning(s)." -ForegroundColor Green
exit 0
