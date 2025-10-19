#!/bin/bash
# Script to clone/update BE source code for Lambda packaging

set -e


REPO_URL="https://github.com/haiha210/screenshot-service-be.git"
# Detect env from script path: prd, stg, dev
SCRIPT_DIR="$(dirname "$0")"
if [[ "$SCRIPT_DIR" =~ "/prd/" ]]; then
  ENV="prd"
elif [[ "$SCRIPT_DIR" =~ "/stg/" ]]; then
  ENV="stg"
elif [[ "$SCRIPT_DIR" =~ "/dev/" ]]; then
  ENV="dev"
else
  ENV="prd" # default
fi

case "$ENV" in
  prd)
    BRANCH="main" ;;
  stg)
    BRANCH="stagging" ;;
  dev)
    BRANCH="develop" ;;
  *)
    BRANCH="main" ;;
esac

TARGET_DIR="$SCRIPT_DIR/../lambdas/$ENV/be"

if [ -d "$TARGET_DIR/.git" ]; then
  echo "Updating existing BE source in $TARGET_DIR..."
  git -C "$TARGET_DIR" fetch --all
  git -C "$TARGET_DIR" checkout $BRANCH
  git -C "$TARGET_DIR" pull origin $BRANCH
else
  echo "Cloning BE source to $TARGET_DIR..."
  git clone --branch $BRANCH "$REPO_URL" "$TARGET_DIR"
fi

echo "BE source is ready at $TARGET_DIR"

# Run Lambda build script in dist directory
BUILD_SCRIPT="$TARGET_DIR/dist/lambda/build.sh"
if [ -f "$BUILD_SCRIPT" ]; then
  echo "Running Lambda build script in dist..."
  bash "$BUILD_SCRIPT"
  # Move all zip files to aws/lambdas/prd
  ZIP_SRC_DIR="$TARGET_DIR/dist/lambda"
  ZIP_DEST_DIR="$SCRIPT_DIR/../lambdas/prd"
  mkdir -p "$ZIP_DEST_DIR"
  # Remove old zip files before copying new ones
  find "$ZIP_DEST_DIR" -maxdepth 1 -type f -name '*.zip' -exec rm -f {} \;
  find "$ZIP_SRC_DIR" -maxdepth 1 -type f -name '*.zip' -exec mv {} "$ZIP_DEST_DIR" \;
  echo "All zip files moved to $ZIP_DEST_DIR"

  # Copy swagger spec to prd folder
  SWAGGER_SRC="$TARGET_DIR/dist/swagger/api-spec.yaml"
  SWAGGER_DEST="$ZIP_DEST_DIR/api-spec.yaml"
  if [ -f "$SWAGGER_SRC" ]; then
    cp "$SWAGGER_SRC" "$SWAGGER_DEST"
    echo "Swagger spec copied to $SWAGGER_DEST"
  else
    echo "Swagger spec not found: $SWAGGER_SRC"
  fi
else
  echo "Build script not found: $BUILD_SCRIPT"
fi
