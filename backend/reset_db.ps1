Write-Host "Resetting Django SQLite database and migrations..."

# Delete SQLite DB
if (Test-Path "db.sqlite3") {
    Remove-Item db.sqlite3
}

# Delete all migration files except __init__.py
Get-ChildItem -Recurse -Include *.py,*.pyc -Path *\migrations\* |
    Where-Object { $_.Name -ne "__init__.py" } |
    Remove-Item

# Recreate migrations and apply
python manage.py makemigrations
python manage.py migrate

Write-Host "Reset complete!"
