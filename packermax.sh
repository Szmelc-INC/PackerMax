#!/bin/bash

# PackerMax: Compress, split, and extract archives
# Flags:
#   --password="mypassword" (Default: "siusiak")
#   --no-password (Disables password protection for ZIP)
#   --split=Xmb (Splits archive)
#   --extract (Detects and extracts split archives)
#   --bashupload (Uploads packed files to bashupload.com)

ARCHIVE_NAME="dir"
DEFAULT_FORMAT="zip"
FORMAT="$DEFAULT_FORMAT"
PASSWORD="siusiak"  # Default password
USE_PASSWORD=true
SPLIT_SIZE=""
EXTRACT_MODE=false
UPLOAD_MODE=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --password=*)
            PASSWORD="${arg#*=}"
            ;;
        --no-password)
            USE_PASSWORD=false
            ;;
        --split=*)
            SPLIT_SIZE="${arg#*=}"
            SPLIT_SIZE=${SPLIT_SIZE,,}  # Convert to lowercase
            SPLIT_SIZE=${SPLIT_SIZE//mb/M}  # Convert 'mb' to 'M'
            SPLIT_SIZE=${SPLIT_SIZE//gb/G}  # Convert 'gb' to 'G'
            ;;
        --extract)
            EXTRACT_MODE=true
            ;;
        --bashupload)
            UPLOAD_MODE=true
            ;;
        zip|tar.gz|tar.xz|tar.bz2)
            FORMAT="$arg"
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: ./PackerMax [zip|tar.gz|tar.xz|tar.bz2] [--password=PASSWORD] [--no-password] [--split=Xmb] [--extract] [--bashupload]"
            exit 1
            ;;
    esac
done

create_extract_script() {
    cat <<EOF > .packed/extract.sh
#!/bin/bash
echo "[*] Extracting archive in \$(pwd)..."

if ls dir.zip.* 1>/dev/null 2>&1; then
    cat dir.zip.* > dir.zip && unzip dir.zip && rm dir.zip.* && rm dir.zip
elif ls dir.tar.gz.* 1>/dev/null 2>&1; then
    cat dir.tar.gz.* > dir.tar.gz && tar -xvf dir.tar.gz && rm dir.tar.gz.* && rm dir.tar.gz
elif ls dir.tar.xz.* 1>/dev/null 2>&1; then
    cat dir.tar.xz.* > dir.tar.xz && tar -xvf dir.tar.xz && rm dir.tar.xz.* && rm dir.tar.xz
elif ls dir.tar.bz2.* 1>/dev/null 2>&1; then
    cat dir.tar.bz2.* > dir.tar.bz2 && tar -xvf dir.tar.bz2 && rm dir.tar.bz2.* && rm dir.tar.bz2
else
    echo "[!] No split archive found!"
    exit 1
fi

echo "[✔] Extraction complete!"
rm -- "\$0"
EOF
    chmod +x .packed/extract.sh
    echo "[✔] Added .packed/extract.sh for easy extraction."
}

extract() {
    echo "[*] Extracting from .packed/..."
    cd .packed || { echo "[!] .packed/ not found!"; exit 1; }
    ./extract.sh
    exit 0
}

upload() {
    echo "[*] Uploading packed files to bashupload.com..."
    > msg.md  # Clear msg.md before appending

    for file in .packed/*; do
        [[ -f "$file" ]] || continue
        echo "[*] Uploading $file..."
        curl bashupload.com -T "$file" >> msg.md
        echo "" >> msg.md
    done

    echo "[✔] Upload complete! Links saved in msg.md."
    cat msg.md
}

pack() {
    mkdir -p .packed  # Ensure .packed/ exists

    case "$FORMAT" in
        zip)
            if [[ "$USE_PASSWORD" == true ]]; then
                zip_cmd="zip -r -P \"$PASSWORD\" \"${ARCHIVE_NAME}.zip\" ./*"
                echo "[*] Using password: $PASSWORD"
            else
                zip_cmd="zip -r \"${ARCHIVE_NAME}.zip\" ./*"
                echo "[*] No password used for ZIP."
            fi

            if [[ -n "$SPLIT_SIZE" ]]; then
                eval "$zip_cmd" && split -b "$SPLIT_SIZE" -d "${ARCHIVE_NAME}.zip" ".packed/${ARCHIVE_NAME}.zip."
                rm "${ARCHIVE_NAME}.zip"
                create_extract_script
                echo "[✔] Split into .packed/${ARCHIVE_NAME}.zip.00X"
            else
                eval "$zip_cmd" && mv "${ARCHIVE_NAME}.zip" .packed/
            fi
            ;;
        tar.gz|tar.xz|tar.bz2)
            tar_cmd="tar -cf - ./*"

            case "$FORMAT" in
                tar.gz) tar_cmd+=" | gzip" ;;
                tar.xz) tar_cmd+=" | xz" ;;
                tar.bz2) tar_cmd+=" | bzip2" ;;
            esac

            if [[ -n "$SPLIT_SIZE" ]]; then
                eval "$tar_cmd" | split -b "$SPLIT_SIZE" -d - ".packed/${ARCHIVE_NAME}.${FORMAT}."
                create_extract_script
                echo "[✔] Split into .packed/${ARCHIVE_NAME}.${FORMAT}.00X"
            else
                eval "$tar_cmd -c > ${ARCHIVE_NAME}.${FORMAT}" && mv "${ARCHIVE_NAME}.${FORMAT}" .packed/
            fi
            ;;
        *)
            echo "Unsupported format: $FORMAT"
            echo "Supported formats: zip, tar.gz, tar.xz, tar.bz2"
            exit 1
            ;;
    esac
    echo "[✔] Packed as .packed/${ARCHIVE_NAME}.${FORMAT}"

    if [[ "$UPLOAD_MODE" == true ]]; then
        upload
    fi
}

# Run extraction if --extract is used
if [[ "$EXTRACT_MODE" == true ]]; then
    extract
else
    pack
fi
