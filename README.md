# patchwork
An easy, simple base kit for iOS app.

## What patchwork supply:
* Base Business Model:
  * json <-> model mappings: via YYModel
  * DB   <-> model mappings: active record
* Database Manager:
  * supports multi-database
  * auto database migration (I'm not sure if this feature should be supported, because in many complex apps, engineers likes to manually migration data from old version to new version)
* Network Manager:
  * Base request
  * HttpRequestAdaptor (ASI, AFN, ...)
