# patchwork
An easy, simple base kit for iOS app.

## What patchwork supplies:
* Base Business Model:
  * json <-> model mappings: via YYModel
  * DB   <-> model mappings: active record
* Database Manager:
  * supports multi-database
  * auto database migration (I'm not sure if this feature should be supported, because in many complex apps, engineers would like to  migrate data from old version to new version manually)
* Network Manager:
  * Base request
  * HttpRequestAdaptor (ASI, AFN, ...)
