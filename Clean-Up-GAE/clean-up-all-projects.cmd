@echo off
gcloud projects list | tail -n +2 > .tmp/.projects
cat .tmp/.projects | awk "{print $1;}" > .tmp/.project_ids
for /F "tokens=*" %%P in (.tmp/.project_ids) do call :Project %%P
exit

:Project
set project=%1
echo GAE Project %project% Stopped Versions:
gcloud app versions list --project=touch-galleries | grep STOPPED > .tmp/%project%-stopped-versions.txt
type .tmp/%project%-stopped-versions.txt
exit /B
