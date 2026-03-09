# Module Directory Structure Reference

```
app/code/{Vendor}/{ModuleName}/
├── Api/
│   └── Data/                    # Data interfaces
├── Block/                       # Block classes (prefer ViewModel)
├── Console/
│   └── Command/                 # CLI commands
├── Controller/
│   ├── Adminhtml/               # Admin controllers
│   └── {FrontName}/             # Frontend controllers
├── Cron/                        # Cron job classes
├── etc/
│   ├── adminhtml/               # Admin-area configs
│   │   ├── menu.xml
│   │   ├── routes.xml
│   │   └── system.xml
│   ├── frontend/                # Frontend-area configs
│   │   └── routes.xml
│   ├── module.xml               # Required
│   ├── di.xml
│   ├── acl.xml
│   ├── config.xml
│   ├── crontab.xml
│   ├── db_schema.xml
│   ├── events.xml
│   └── webapi.xml
├── Helper/                      # Helper classes
├── i18n/                        # Translation CSV files
├── Model/
│   └── ResourceModel/
│       └── {Entity}/
│           └── Collection.php
├── Observer/                    # Event observers
├── Plugin/                      # Interceptor plugins
├── Setup/
│   └── Patch/
│       ├── Data/                # Data patches
│       └── Schema/              # Schema patches
├── Ui/                          # UI components
├── ViewModel/                   # View models (preferred over Block)
├── view/
│   ├── adminhtml/
│   │   ├── layout/
│   │   ├── templates/
│   │   └── web/
│   └── frontend/
│       ├── layout/
│       ├── templates/
│       └── web/
├── composer.json                # Required
└── registration.php             # Required
```
