# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Campy is a Rails 8 project management application built with PostgreSQL, Hotwire (Turbo & Stimulus), and Devise authentication. It provides collaborative project tracking with activities, Gantt chart visualization, team messaging, and file attachments.

**Tech Stack:**
- Rails 8.0.3 with Ruby 3.4.7
- PostgreSQL database
- Hotwire (Turbo Rails + Stimulus controllers)
- Devise for authentication
- Importmap for JavaScript (no Node.js build step)
- Prawn for PDF generation (Gantt charts)
- Solid Cache/Queue/Cable for background jobs and caching

## Development Commands

### Starting the application
```bash
bin/setup              # Initial setup (creates DB, loads schema, installs dependencies)
bin/rails server       # Start development server (default: http://localhost:3000)
bin/dev                # Start server with other services if configured
```

### Database
```bash
bin/rails db:create          # Create database
bin/rails db:migrate         # Run pending migrations
bin/rails db:schema:load     # Load schema into database
bin/rails db:reset           # Drop, create, and load schema
bin/rails db:seed            # Load seed data
```

### Testing
```bash
bin/rails test                                    # Run all tests in parallel
bin/rails test test/models/user_test.rb          # Run specific test file
bin/rails test test/models/user_test.rb:15       # Run specific test at line number
bin/rails test:system                             # Run system tests with Selenium
```

### Code Quality
```bash
bin/rubocop                    # Run linter (Omakase Ruby style)
bin/rubocop -A                 # Auto-correct violations
bin/brakeman                   # Security vulnerability scan
```

### Console & Debugging
```bash
bin/rails console              # Rails console (aliases: bin/rails c)
bin/rails dbconsole            # Direct database console
```

### Email preview (Development only)
Visit `/letter_opener` to view emails sent in development (letter_opener_web gem).

## Core Architecture

### Data Model Hierarchy

**Projects** are the top-level entity owned by a User:
- Each project has one owner and multiple optional members (via `project_memberships`)
- Access control: `Project.accessible_to(user)` scope returns projects owned by or shared with the user
- Projects contain activities, and can send email invitations (`project_invitations`)

**Activities** (tasks) belong to projects:
- Activities have assignees, disciplines, zones, start/end dates, and duration
- Validation: assignee must be a team member of the project
- Comments (with file attachments and reactions) are nested under activities
- Comments support threading via `parent_id` (replies)

**Users & Team Collaboration:**
- Users authenticate via Devise
- Users can own projects or be members of projects
- `User#teammates` returns all users from shared projects
- `User#display_name` shows username or email
- Users have avatars (Active Storage) and theme preferences (light/dark)
- New users automatically accept pending project invitations by email

**Conversations (Direct Messaging):**
- Multi-party conversations via `conversation_memberships` join table
- `Conversation.between(user_ids)` finds exact matches for group chats
- Messages belong to conversations and users

**Reference Data:**
- Disciplines and Zones are global lookup tables for categorizing activities

### Controllers & Routes

Key routes (`config/routes.rb`):
- Root path: redirects to projects index for authenticated users, home page otherwise
- Nested resources: `projects → activities → comments → comment_reactions`
- Project member management: `project_memberships` (create/destroy only)
- Project invitations: `project_invitations` (destroy only - creation happens via mailer)
- `/my-activities` - shows activities assigned to current user
- Gantt chart: `/projects/:id/gantt`
- Conversations: index, show, create with nested messages

### Frontend Architecture

**JavaScript (Stimulus Controllers):**
All JavaScript is organized as Stimulus controllers in `app/javascript/controllers/`:
- `gantt_controller.js` - Interactive Gantt chart rendering
- `date_picker_controller.js` - Date selection UI
- `duration_controller.js` - Calculates end dates from duration inputs
- `modal_controller.js` - Modal dialog management
- `messages_controller.js` - Real-time messaging UI
- `theme_controller.js` - Dark/light mode toggle
- `status_column_controller.js` - Status column interactions
- `flash_toast.js` - Toast notification system (non-controller utility)

**Assets:**
- CSS: `app/assets/stylesheets/application.css` (custom styling, no CSS framework)
- Importmap: JavaScript dependencies managed via `config/importmap.rb`
- Vendor JS: Day.js included in `vendor/javascript/` for date manipulation

### Background Jobs & Services

**Reports:**
- `app/services/reports/gantt_pdf.rb` - Generates PDF Gantt charts using Prawn
- Renders landscape A3 PDFs with month/week timeline headers
- Color-coded bars for planned vs completed activities
- Includes disciplines, zones, assignees, and duration in visualization

**Jobs:**
- Rails 8 uses Solid Queue for background jobs (in-database queue)

**Email:**
- `ProjectInvitationMailer` sends invitation emails with secure tokens
- Letter Opener Web for development email preview

### Key Patterns & Conventions

**Access Control:**
- Always check `project.accessible_by?(current_user)` before allowing project access
- Use `Project.accessible_to(current_user)` scope in queries
- Activity assignees must be validated as team members: `activity.assignee_is_part_of_project`

**Associations:**
- Use `shallow: true` for nested routes to keep URLs clean (routes.rb line 15)
- Activities use `belongs_to :assignee, class_name: "User"` pattern for role-specific associations
- Comments support self-referential threading via `parent_id`

**Validations:**
- Activities validate `due_on >= start_on` and `duration_days > 0`
- Activities auto-calculate `due_on` from `start_on + duration_days`
- Usernames: lowercase, alphanumeric + underscores, max 30 chars

**Callbacks:**
- `User#accept_pending_invitations` runs on create to auto-join invited projects
- Activities set default dates on initialization

**Testing:**
- Tests use fixtures from `test/fixtures/`
- Parallel test execution enabled by default
- Devise test helpers included in IntegrationTest

## Common Patterns

### Creating activities with proper validation
Activities require `start_on` and validate that assignees belong to the project. Always ensure the assignee is a team member before assignment.

### Gantt chart date ranges
The Gantt PDF service expects `timeline_start`, `timeline_end`, and a collection of activities. It handles pagination, weekend shading, and month/week headers automatically.

### Finding or creating conversations
Use `Conversation.between([user1.id, user2.id])` to find existing conversations or create a new one if none exists.

### Project access scoping
Always use `Project.accessible_to(current_user)` in controllers to ensure users only see authorized projects.
