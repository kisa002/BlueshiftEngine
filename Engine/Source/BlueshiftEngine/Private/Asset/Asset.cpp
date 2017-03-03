#include "Precompiled.h"
#include "Asset/Asset.h"
#include "Asset/GuidMapper.h"
#include "Asset/AssetImporter.h"
#include "File/FileSystem.h"

BE_NAMESPACE_BEGIN

ABSTRACT_DECLARATION("Asset", Asset, Object)
BEGIN_EVENTS(Asset)
END_EVENTS
BEGIN_PROPERTIES(Asset)
    PROPERTY_OBJECT("guid", "GUID", "GUID", Guid::zero.ToString(), Object::metaObject, PropertySpec::ReadWrite | PropertySpec::Hidden),
    PROPERTY_STRING("timeStamp", "Time Stamp", "Timestamp", "0", PropertySpec::ReadWrite | PropertySpec::Hidden),
END_PROPERTIES

const SignalDef SIG_Reloaded("reloaded");
const SignalDef SIG_Modified("modified", "i");

Asset::Asset() {
    node.SetOwner(this);
    assetImporter = nullptr;
    isStoredInDisk = false;
    isRedundantAsset = false;
}

Asset::~Asset() {
    if (assetImporter) {
        AssetImporter::DestroyInstanceImmediate(assetImporter);
    }
}

const Str Asset::NormalizeAssetPath(const Str &assetPath) {
    Str normalizedAssetPath = assetPath;

    Str::ConvertPathSeperator(normalizedAssetPath, PATHSEPERATOR_CHAR);

    return normalizedAssetPath;
}

const Str Asset::GetMetaFilenameFromAssetPath(const char *assetPath) {
    Str metaFilename = Asset::NormalizeAssetPath(assetPath);
    metaFilename += ".meta";

    return metaFilename;
}

const Str Asset::GetCacheDirectory(const char *baseLibraryDir) const {
    Str cacheDir = baseLibraryDir;
    cacheDir.AppendPath("metadata");
    cacheDir.AppendPath(va("%s", GetGuid().ToString(Guid::DigitsWithHyphens)));

    Str::ConvertPathSeperator(cacheDir, PATHSEPERATOR_CHAR);
    
    return cacheDir;
}

const Str Asset::GetAssetFilename() const {
    Str assetPath;
    const Asset *asset = this;
    
    while (asset) {
        Str tempPath = asset->name;
        tempPath.AppendPath(assetPath);
        assetPath = tempPath;

        asset = asset->node.GetParent();
    }

    return assetPath;
}

const Str Asset::GetResourceFilename() const {
    Str name;

    if (assetImporter) {
        name = assetImporter->GetCacheFilename();
    } else {
        name = Asset::NormalizeAssetPath(GetAssetFilename());
    }

    return name;
}

void Asset::GetChildren(Array<Asset *> &children) const {
    for (Asset *child = node.GetChild(); child; child = child->node.GetNextSibling()) {
        children.Append(child);
        child->GetChildren(children);
    }
}

void Asset::WriteMetaDataFile() const {
    Str metaFilename = Asset::GetMetaFilenameFromAssetPath(GetAssetFilename());

    Json::Value metaDataValue;
    props->Serialize(metaDataValue);

    if (assetImporter) {
        Json::Value importerValue;
        assetImporter->props->Serialize(importerValue);

        metaDataValue["importer"] = importerValue;
    }
 
    Json::StyledWriter jsonWriter;
    Str jsonText = jsonWriter.write(metaDataValue).c_str();

    fileSystem.WriteFile(metaFilename, jsonText.c_str(), jsonText.Length());
}

void Asset::SetModified(bool modified) {
    EmitSignal(&SIG_Modified, modified ? 1 : 0);
}

BE_NAMESPACE_END