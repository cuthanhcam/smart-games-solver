# PowerShell script to update all import paths in Flutter project

$libPath = "d:\Workspace\smart-games-solver\mobile\lib"

# Define mapping of old paths to new paths
$pathMappings = @{
    "import '../repositories/auth_repository.dart'" = "import '../../auth/repositories/auth_repository.dart'"
    "import 'repositories/auth_repository.dart'" = "import 'features/auth/repositories/auth_repository.dart'"
    
    "import '../screens/login_page.dart'" = "import '../../auth/screens/login_page.dart'"
    "import '../screens/login_screen.dart'" = "import '../../auth/screens/login_screen.dart'"
    "import '../screens/register_page.dart'" = "import '../../auth/screens/register_page.dart'"
    "import '../screens/register_screen.dart'" = "import '../../auth/screens/register_screen.dart'"
    "import 'screens/home_page.dart'" = "import 'features/home/screens/home_page.dart'"
    "import 'screens/login_page.dart'" = "import 'features/auth/screens/login_page.dart'"
    "import '../screens/home_page.dart'" = "import '../../home/screens/home_page.dart'"
    
    "import '../services/api_client.dart'" = "import '../../../shared/services/api_client.dart'"
    "import '../services/api_service.dart'" = "import '../../../shared/services/api_service.dart'"
    "import '../services/auth_service.dart'" = "import '../../auth/services/auth_service.dart'"
    
    "import '../models/user.dart'" = "import '../../../shared/models/user.dart'"
    "import '../models/app_user.dart'" = "import '../../../shared/models/app_user.dart'"
    "import '../models/message.dart'" = "import '../../../shared/models/message.dart'"
    "import '../models/announcement.dart'" = "import '../../../shared/models/announcement.dart'"
    "import '../models/sudoku.dart'" = "import '../../../shared/models/sudoku.dart'"
    "import '../models/game_2048.dart'" = "import '../../../shared/models/game_2048.dart'"
    "import '../models/caro.dart'" = "import '../../../shared/models/caro.dart'"
    
    "import '../widgets/" = "import '../../../shared/widgets/"
    "import '../utils/api_config.dart'" = "import '../../../core/config/api_config.dart'"
    "import '../utils/user_activity_helper.dart'" = "import '../../profile/utils/user_activity_helper.dart'"
    "import '../utils/leaderboard_helper.dart'" = "import '../../leaderboard/utils/leaderboard_helper.dart'"
    
    "import '../screens/leaderboard_screen.dart'" = "import '../../leaderboard/screens/leaderboard_screen.dart'"
    "import '../screens/user_activity_screen.dart'" = "import '../../profile/screens/user_activity_screen.dart'"
    "import '../screens/friends_screen.dart'" = "import '../../social/screens/friends_screen.dart'"
    "import '../screens/admin_page.dart'" = "import '../../admin/screens/admin_page.dart'"
    "import '../screens/announcement_screen.dart'" = "import '../../announcement/screens/announcement_screen.dart'"
    "import '../screens/chat_list_screen.dart'" = "import '../../social/screens/chat_list_screen.dart'"
    "import '../screens/notifications_screen.dart'" = "import '../../announcement/screens/notifications_screen.dart'"
    "import '../screens/user_profile_screen.dart'" = "import '../../profile/screens/user_profile_screen.dart'"
    "import '../screens/chat_detail_screen.dart'" = "import '../../social/screens/chat_detail_screen.dart'"
    
    "import '../repositories/message_repository.dart'" = "import '../repositories/message_repository.dart'"
    "import '../repositories/friend_request_repository.dart'" = "import '../repositories/friend_request_repository.dart'"
    "import '../repositories/announcement_repository.dart'" = "import '../../announcement/repositories/announcement_repository.dart'"
}

Write-Host "Updating import paths in Flutter project..." -ForegroundColor Green

Get-ChildItem -Path $libPath -Filter *.dart -Recurse | ForEach-Object {
    $file = $_
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    foreach ($old in $pathMappings.Keys) {
        $new = $pathMappings[$old]
        if ($content -match [regex]::Escape($old)) {
            $content = $content -replace [regex]::Escape($old), $new
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Updated: $($file.FullName)" -ForegroundColor Yellow
    }
}

Write-Host "Import path update completed!" -ForegroundColor Green
