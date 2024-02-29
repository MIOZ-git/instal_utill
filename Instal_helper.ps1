# Указываем путь к сетевой папке
$path = '\\путь\к\папке\с\установщиками'

# Создаем лог-файл
$logFile = "C:\logs\installation_log.txt"
Add-Content -Path $logFile -Value "Начало лога $(Get-Date)" -Force

# Функция для поиска установочных файлов в папке
function Find-InstallationFiles {
    param (
        [string]$folderPath,
        [ref]$count  # Ссылка на счетчик
    )

    # Создаем массив для хранения результатов
    $results = @()

    # Получаем список файлов в папке
    $files = Get-ChildItem -Path $folderPath -File

    # Проверяем каждый файл на наличие расширения .exe или .msi
    foreach ($file in $files) {
        if ($file.Extension -eq '.exe' -or $file.Extension -eq '.msi') {
            # Получаем метаданные установочного файла
            $fileInfo = Get-ItemProperty -Path $file.FullName

            # Добавляем информацию о файле в массив результатов с учетом текущего значения счетчика
            $results += "$($count.Value)) $($fileInfo.Name) - $($file.FullName)"
            $count.Value++
        }
    }

    # Рекурсивно вызываем функцию для каждой подпапки
    $folders = Get-ChildItem -Path $folderPath -Directory
    foreach ($folder in $folders) {
        $subResults = Find-InstallationFiles -folderPath $folder.FullName -count $count
        $results += $subResults  # Добавляем результаты из подпапки в общий массив
    }

    return ,$results  # Возвращаем массив результатов как один объект
}

# Функция для установки выбранного пакета
function Install-SelectedPackage {
    param (
        [string]$packagePath,
        [string]$logFile  # Добавляем параметр для пути к лог-файлу
    )

    # Проверяем существование файла
    if (Test-Path $packagePath) {
        # Запускаем установку выбранного пакета
        Start-Process -FilePath $packagePath -Wait
        Add-Content -Path $logFile -Value "Установлен пакет: $packagePath"  # Записываем информацию в лог-файл
    } else {
        Write-Host "Файл не найден: $packagePath"
        Add-Content -Path $logFile -Value "Файл не найден: $packagePath"  # Записываем информацию в лог-файл
    }
}

# Инициализируем счетчик для нумерации
$count = 1

# Вызываем функцию для указанной папки
$results = Find-InstallationFiles -folderPath $path -count ([ref]$count)

# Выводим результаты из массива
$results | ForEach-Object { Write-Host $_ }

# Бесконечный цикл для ожидания действий пользователя
while ($true) {
    # Запрашиваем у пользователя номер выбранного пакета
    $choice = Read-Host "Выберите номер файла для установки (0 для выхода)"

    # Преобразуем введенное значение в число
    $choice = [int]$choice

    # Получаем список установочных файлов
    $installationFiles = Get-ChildItem -Path $path -Recurse | Where-Object { $_.Extension -eq '.exe' -or $_.Extension -eq '.msi' }

    # Проверяем, что выбранный номер находится в допустимом диапазоне
    if ($choice -gt 0 -and $choice -le $installationFiles.Count) {
        # Получаем путь к выбранному пакету
        $selectedFile = $installationFiles[$choice - 1].FullName

        # Вызываем функцию для установки выбранного пакета и передаем путь к лог-файлу
        Install-SelectedPackage -packagePath $selectedFile -logFile $logFile
    } elseif ($choice -eq 0) {
        # Выход из бесконечного цикла при вводе 0
        break
    } else {
        Write-Host "Недопустимый номер файла: $choice"
    }
}
