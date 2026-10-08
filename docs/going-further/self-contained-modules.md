# Self-Contained Modules

With the `modules` layout, everything a feature needs can live in one folder that you copy to the next project. Its migrations, listeners and factories come with it.

## Adding the File Types You Use

The `modules` layout already keeps models, migrations, factories, actions, events, listeners and jobs inside each module. Add the file types you use most:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')
    ->kind('view-model', in: 'Modules/{module}/ViewModels', label: 'View model')
    ->kind('value-object', in: 'Modules/{module}/ValueObjects', command: 'mod:value', label: 'Value object');
```

`command:` names the command, and `label:` is the noun its output uses.

## Building Two Modules

Build a `Knowledge` module that stores documents, and an `Agents` module that answers questions about them:

```bash
php artisan mod:model Knowledge:Document -mf --controller --resource --requests
php artisan mod:action Knowledge:IndexDocument
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

## Copying a Module to Another Project

Each module is one folder. Copy either into another project that uses the same layout, including the same `Mod::layout('modules')` lines, and its migrations, listeners and factories come with it:

```bash
php artisan migrate --pretend
# -> includes 2026_10_08_120000_create_documents_table

php artisan event:list --event=DocumentUploaded
# -> App\Modules\Knowledge\Events\DocumentUploaded
# ->   ⇂ App\Modules\Knowledge\Listeners\GenerateEmbeddings@handle
```

`Document::factory()` finds the module's factory, as in the first project.
