@echo off
cd /d "%~dp0src"
echo Sirviendo Karma MVP en http://localhost:8000 ...
python -m http.server 8000
