# AGENTS.md - AI Coding Agent Guidelines

## Project Overview

**BX Framework** - A custom PHP MVC framework (v1.0) for card/license management system.
- **Language**: PHP 8.0+
- **Architecture**: MVC (Model-View-Controller)
- **Database**: MySQL with PDO
- **Web Server**: Apache (with mod_rewrite) or Nginx

## Project Structure

```
BX_wlyz/
├── app/                    # Application modules
│   ├── admin/             # Admin module (controller/, model/)
│   ├── agent/             # Agent module
│   ├── api/               # API endpoints
│   ├── common/            # Shared components
│   └── index/             # Frontend module
├── core/                  # Framework core
│   ├── lib/              # Core libraries (Db.php, Route.php, Config.php, etc.)
│   ├── function/         # Helper functions (function.php)
│   ├── common.php        # Framework bootstrap
│   └── version.php       # Version constant
├── config/                # Configuration files
│   ├── config.php        # Main config (DB, timezone, defaults)
│   └── route.php         # URL routing rules
├── template/              # View templates
│   └── default/          # Theme directory
├── public/                # Static assets (css/, js/, images/)
└── install/               # Installation wizard
```

## Build/Test/Lint Commands

**Note**: This project does not have automated testing, linting, or build tools configured.

### Manual Testing
```bash
# Start local PHP server for testing
php -S localhost:8000

# Syntax check a PHP file
php -l app/admin/controller/Card.php

# Check all PHP files for syntax errors
find . -name "*.php" -exec php -l {} \;
```

### Database Setup
- Run installer at `/install` after setting DB credentials in `config/config.php`
- Default admin credentials: `admin` / `admin`

## Code Style Guidelines

### PHP Standards

**File Structure:**
- Use `<?php` opening tag (no short tags)
- Files must end without closing `?>` tag
- Namespace declaration immediately after `<?php`
- Example:
```php
<?php
namespace app\admin\controller;
use core\lib\Db;
use app\admin\model\Card as model;

class Card extends Common {
    // ...
}
```

**Naming Conventions:**
- **Classes**: PascalCase (e.g., `Card`, `UserController`)
- **Methods**: camelCase (e.g., `getInfo`, `isLogin`)
- **Variables**: snake_case (e.g., `$card_type_id`, `$user_data`)
- **Constants**: UPPER_CASE (e.g., `BX_ROOT`, `DS`)
- **Database tables**: Lowercase with prefix (e.g., `bx_card`, `bx_user`)

**Imports & Namespaces:**
- Always use explicit `use` statements at top of file
- Order: Framework core first, then application modules
```php
use core\lib\Db;
use core\lib\Config;
use app\admin\Auth;
use app\admin\model\Card as model;
```

**Formatting:**
- Indent: Tab-based (observed in codebase)
- Brace style: K&R (opening brace on same line for classes/functions)
```php
class Card extends Common {
    function __construct() {
        parent::isLogin();
        $this->model = new model;
    }
}
```

### MVC Patterns

**Controllers** (`app/{module}/controller/`):
- Extend `Common` base class
- Use `parent::isLogin()` in constructor for auth check
- Method naming: action verbs (e.g., `add`, `edit`, `delete`, `lists`, `getInfo`)
- Access POST data via `$_POST`, GET via `$_POST` or path params
- Return JSON responses using `bx_msg()` or `bx_lists()` helpers

**Models** (`app/{module}/model/`):
- Extend `Common` model class
- Initialize with `parent::init()` in constructor
- Use `$this->con` (Db instance) for database operations
- Use `$this->log` for audit logging
- Database methods: `select()`, `insert()`, `update()`, `delete()`

**Views** (`template/default/{module}/`):
- PHP-based templates (not Twig/Blade)
- Access config via `$config` array
- Use `__URL__` constant for base URL
- Include security check: `<?php if(!defined('BX_ROOT')) {exit();} ?>`

### Security Guidelines

**CRITICAL - SQL Injection Risk:**
- Current codebase has SQL injection vulnerabilities
- Always use prepared statements via `Db::insert()`, `Db::update()`
- Avoid string interpolation in SQL: BAD: `"id = {$id}"`
- Use parameterized queries when possible

**Input Handling:**
- Access POST data: `isset($_POST['key']) ? $_POST['key'] : ''`
- Validate numeric inputs: `is_numeric($_POST['point'])`
- Use `post_id()` helper for ID parameters
- Use `post_lists()` helper for pagination

**Output Encoding:**
- Use `htmlspecialchars()` for HTML output
- Helper available: `new_html_special_chars()`
- JSON responses: Use `bx_msg()` and `bx_lists()` helpers

### Database Conventions

**Table Naming:**
- Prefix: `bx_` (configurable)
- Join tables: Use `pre_` prefix in queries (replaced with actual prefix)

**Query Patterns:**
```php
// SELECT with joins
$res = $this->con->select('card', $where, 
    'LEFT JOIN pre_software ON pre_card.software_id = pre_software.id',
    'id', '0,10', '*'
);

// INSERT
$this->con->insert('card', $data_array);

// UPDATE
$this->con->update('card', $data_array, "id={$id}");

// DELETE
$this->con->delete('card', "id in ({$ids})");
```

### Helper Functions

**Framework Helpers** (`core/function/function.php`):
- `show_error($msg)` - Display error page
- `bx_msg($title, $text, $state, $type)` - JSON message response
- `bx_lists($data, $count)` - JSON list response with pagination
- `sql_and($where_array)` - Build WHERE clause from conditions
- `addslashes_deep($value)` - Recursive escaping
- `get_ip()` - Get client IP address
- `create_card()` - Generate unique card string

**Authentication:**
- `Auth::check()` - Verify user is logged in
- `Auth::get('field')` - Get current user data
- `parent::isLogin()` - Controller auth guard

## URL Routing

**Pattern**: `/{module}/{controller}/{action}`
- Module: `admin`, `agent`, `api`, `index`
- Controller: Class name without suffix (e.g., `Card` → `Card.php`)
- Action: Method name (e.g., `lists`, `add`)

**Examples:**
- `/admin/Card/lists` → `app\admin\controller\Card::lists()`
- `/agent/Home/show` → `app\agent\controller\Home::show()`

## Environment Requirements

- PHP 8.0+
- MySQL 5.7+
- PDO extension enabled
- mod_rewrite (Apache) or equivalent URL rewriting
- `magic_quotes_gpc` disabled (handled in code)

## Development Notes

1. **No Dependency Manager**: No Composer - all libraries in `core/lib/`
2. **No Test Suite**: No PHPUnit or testing framework
3. **No Build Process**: Direct PHP execution
4. **Security Warning**: Codebase contains SQL injection vulnerabilities - use prepared statements
5. **Legacy Code**: Adapted for PHP 8.0, originally written for older PHP versions
