#!/usr/bin/env pwsh
# Script to update all imports to use shared resources

$rootPath = "D:\Workspace\smart-games-solver\mobile\lib"

# Define replacement patterns
$replacements = @{
    "import '../services/api_client.dart';" = "import '../../../shared/services/api_client.dart';"
    "import '../services/api_service.dart';" = "import '../../../shared/services/api_service.dart';"
    "import '../models/announcement.dart';" = "import '../../../shared/models/announcement.dart';"
    "import '../models/app_user.dart';" = "import '../../../shared/models/app_user.dart';"
    "import '../models/caro.dart';" = "import '../../../shared/models/caro.dart';"
    "import '../models/game_2048.dart';" = "import '../../../shared/models/game_2048.dart';"
    "import '../models/message.dart';" = "import '../../../shared/models/message.dart';"
    "import '../models/sudoku.dart';" = "import '../../../shared/models/sudoku.dart';"
    "import '../models/user.dart';" = "import '../../../shared/models/user.dart';"
    "import '../widgets/" = "import '../../../shared/widgets/"
    "import '../../widgets/" = "import '../../shared/widgets/"
}

# Get all dart files
$dartFiles = Get-ChildItem -Path $rootPath -Filter "*.dart" -Recurse

foreach ($file in $dartFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $modified = $false
    
    foreach ($pattern in $replacements.Keys) {
        if ($content -match [regex]::Escape($pattern)) {
            $content = $content -replace [regex]::Escape($pattern), $replacements[$pattern]
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Updated: $($file.FullName)"
    }
}

Write-Host "`nDone! All imports have been updated."
