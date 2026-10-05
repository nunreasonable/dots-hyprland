pragma Singleton

import Quickshell
import qs.modules.common.functions

Singleton {
    // Formats
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]

    function isValidImageByName(name: string): bool {
        return validImageExtensions.some(t => name.endsWith(`.${t}`));
    }

    // Thumbnails
    // https://specifications.freedesktop.org/thumbnail-spec/latest/directory.html
    readonly property var thumbnailSizes: ({
        "normal": 128,
        "large": 256,
        "x-large": 512,
        "xx-large": 1024
    })
    function thumbnailSizeNameForDimensions(width: int, height: int): string {
        const sizeNames = Object.keys(thumbnailSizes);
        for(let i = 0; i < sizeNames.length; i++) {
            const sizeName = sizeNames[i];
            const maxSize = thumbnailSizes[sizeName];
            if (width <= maxSize && height <= maxSize) return sizeName;
        }
        return "xx-large";
    }

    function thumbnailPathFor(filePath: string, sizeName: string): string {
        if (!filePath || filePath.length === 0) return "";
        const resolvedUrlWithoutFileProtocol = FileUtils.trimFileProtocol(`${Qt.resolvedUrl(filePath)}`);
        const encodedUrlWithoutFileProtocol = resolvedUrlWithoutFileProtocol.split("/").map(part => encodeURIComponent(part)).join("/");
        const md5Hash = Qt.md5(`file://${encodedUrlWithoutFileProtocol}`);
        return `${Directories.genericCache}/thumbnails/${sizeName}/${md5Hash}.png`;
    }
}
