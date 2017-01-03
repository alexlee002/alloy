# patchwork

![badge-pod] ![badge-languages] ![badge-pms] ![badge-platforms] ![badge-apache2]

Patchwork is a simple toolkit that makes your iOS / OS X apps development more easier.

[中文文档](./Patchwork 开发文档.md) | English Document

##Important!
The `BlocksKit` defines a macro named `SELECT`, which is conflict with the property name in `ALDatabase`,  so **BE SURE** add this code in your `Podfile`:

```Ruby
pre_install do
    system("sed -i '' '/BKMacros/d' Pods/BlocksKit/BlocksKit/BlocksKit.h")
end
```
