# patchwork
An easy, simple base kit for iOS app.

##Important!
The `BlocksKit` defines a macro named `SELECT`, which is conflict with the property name in `ALDatabase`,  so **BE SURE** add this code in your `Podfile`:

```Ruby
pre_install do
    system("sed -i '' '/BKMacros/d' Pods/BlocksKit/BlocksKit/BlocksKit.h")
end
```

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


