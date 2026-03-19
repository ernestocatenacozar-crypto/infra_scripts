echo "[upload_to_bunny] Ejecutando docker run..."; docker run --rm --entrypoint sh \
  -e BUNNY_STORAGE_ZONE="orbitastorage" \
  -e BUNNY_STORAGE_API_KEY="a5ebdb10-e74d-45d6-8934617053f9-5f56-4b14" \
  -e CITY_SLUG="$CITY_SLUG" \
  -v /home/ubuntu/work/frontend_build/test_frontend/dist:/app/dist \
  infra_scripts-test_frontend:latest \
  -c "set -eu; cd /app/dist/$CITY_SLUG; lftp -u \"orbitastorage,a5ebdb10-e74d-45d6-8934617053f9-5f56-4b14\" storage.bunnycdn.com -e \"cd $CITY_SLUG; mirror -R --parallel=25 . .; bye\""