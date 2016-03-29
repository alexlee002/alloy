# patchwork
An easy, simple base kit for iOS app.

[中文文档](./Patchwork 开发文档.md) | English Document

##Important!
The `BlocksKit` defines a macro named `SELECT`, which is conflict with the property name in `ALDatabase`,  so **BE SURE** add this code in your `Podfile`:

```Ruby
pre_install do
    system("sed -i '' '/BKMacros/d' Pods/BlocksKit/BlocksKit/BlocksKit.h")
end
```
