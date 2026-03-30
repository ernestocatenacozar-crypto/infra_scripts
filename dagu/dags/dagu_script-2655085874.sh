env HOME=/tmp bash -lc 'set -eu; IMAGE="infra_scripts-test_frontend_build:latest"; if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Missing image: $IMAGE";
  echo "Build it first with: docker compose --profile build build test_frontend_build";
  exit 1;
fi; EXTRA_ARGS=""; if [ "0" = "1" ]; then
  EXTRA_ARGS="--no-download-images";
fi; docker run --rm --entrypoint sh -e ORBITA_CITY="Almeria" -v /home/ubuntu/work/frontend_build/test_frontend:/app -v infra_scripts_test_frontend_node_modules:/app/node_modules -v /home/ubuntu/work/frontend_build/test_frontend/dist:/app/dist -v /home/ubuntu/data_storage:/home/ubuntu/data_storage "$IMAGE" scripts/docker_static_entrypoint.sh --city "Almeria" --out "dist" --base-url "$BASE_URL" $EXTRA_ARGS'