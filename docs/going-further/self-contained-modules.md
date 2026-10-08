# Self-Contained Modules

With the `modules` layout, everything a feature needs can live in one folder that you copy to the next project. Its migrations, listeners and factories come with it.

## Building Two Modules

The `modules` layout keeps models, migrations, factories, actions, DTOs, view models, value objects, events, listeners and jobs inside each module. Build a `Knowledge` module that stores documents, and an `Agents` module that answers questions about them:

```bash
php artisan mod:model Knowledge:Document -mf --controller --resource --requests
php artisan mod:action Knowledge:IndexDocument
php artisan mod:dto Knowledge:DocumentData
php artisan mod:event Knowledge:DocumentUploaded
php artisan mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded
php artisan mod:view-model Knowledge:ShowDocument

php artisan mod:model Agents:Conversation -m
php artisan mod:action Agents:AnswerQuestion
php artisan mod:value Agents:TokenUsage
php artisan mod:job Agents:GenerateReply
```

```text
app/Modules/
├── Agents/
│   ├── Actions/
│   │   └── AnswerQuestion.php
│   ├── Database/
│   │   └── Migrations/
│   │       └── 2026_10_08_120001_create_conversations_table.php
│   ├── Jobs/
│   │   └── GenerateReply.php
│   ├── Models/
│   │   └── Conversation.php
│   └── ValueObjects/
│       └── TokenUsage.php
└── Knowledge/
    ├── Actions/
    │   └── IndexDocument.php
    ├── Controllers/
    │   └── DocumentController.php
    ├── Data/
    │   └── DocumentData.php
    ├── Database/
    │   ├── Factories/
    │   │   └── DocumentFactory.php
    │   └── Migrations/
    │       └── 2026_10_08_120000_create_documents_table.php
    ├── Events/
    │   └── DocumentUploaded.php
    ├── Listeners/
    │   └── GenerateEmbeddings.php
    ├── Models/
    │   └── Document.php
    ├── Requests/
    │   ├── StoreDocumentRequest.php
    │   └── UpdateDocumentRequest.php
    └── ViewModels/
        └── ShowDocument.php
```

The DTO and the view model extend base classes that every module shares. The first `mod:dto` and `mod:view-model` write them, once, outside the modules:

```text
   INFO  Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].
   INFO  DTO [app/Modules/Knowledge/Data/DocumentData.php] created successfully.
```

[Generated Base Classes](/going-further/stubs#generated-base-classes) covers where they go and how to change them.

## Copying a Module to Another Project

Each module is one folder. Copy it into another project that uses the `modules` layout, then run `mod:bases` once to write the base classes its DTOs and view models extend:

```bash
php artisan mod:bases
```

```text
   INFO  Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].
   INFO  Created base class App\Support\ViewModels\ViewModel [app/Support/ViewModels/ViewModel.php].
```

The module's migrations, listeners and factories come with it:

```bash
php artisan migrate --pretend
# -> includes 2026_10_08_120000_create_documents_table

php artisan event:list --event=DocumentUploaded
# -> App\Modules\Knowledge\Events\DocumentUploaded
# ->   ⇂ App\Modules\Knowledge\Listeners\GenerateEmbeddings@handle
```

`Document::factory()` finds the module's factory, as in the first project. `mod:bases` never overwrites a base that exists, so running it again writes nothing.
