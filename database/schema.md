## Table `owners`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `name` | `varchar` |  |
| `email` | `varchar` |  Unique |
| `password_hash` | `text` |  |
| `phone` | `varchar` |  Nullable |
| `photo_url` | `text` |  Nullable |
| `language` | `varchar` |  Nullable |
| `currency` | `varchar` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `gyms`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `owner_id` | `int8` |  |
| `name` | `varchar` |  |
| `is_primary` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `staff`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `name` | `varchar` |  |
| `email` | `varchar` |  Unique |
| `password_hash` | `text` |  |
| `phone` | `varchar` |  Nullable |
| `role` | `varchar` |  Nullable |
| `salary` | `numeric` |  Nullable |
| `attendance_enabled` | `bool` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `staff_permissions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `staff_id` | `int8` |  |
| `manage_members` | `bool` |  Nullable |
| `manage_plans` | `bool` |  Nullable |
| `mark_attendance` | `bool` |  Nullable |
| `view_member_analytics` | `bool` |  Nullable |
| `view_finance` | `bool` |  Nullable |
| `download_reports` | `bool` |  Nullable |

## Table `plans`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `name` | `varchar` |  |
| `price` | `numeric` |  |
| `duration_type` | `varchar` |  |
| `duration_value` | `int4` |  |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `members`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `membership_number` | `varchar` |  Nullable |
| `name` | `varchar` |  |
| `photo_url` | `text` |  Nullable |
| `gender` | `varchar` |  Nullable |
| `phone` | `varchar` |  |
| `email` | `varchar` |  Nullable |
| `dob` | `date` |  Nullable |
| `address` | `text` |  Nullable |
| `joined_date` | `date` |  |
| `due_amount` | `numeric` |  Nullable |
| `status` | `varchar` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `member_plans`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `member_id` | `int8` |  |
| `plan_id` | `int8` |  |
| `start_date` | `date` |  |
| `end_date` | `date` |  |
| `plan_price` | `numeric` |  |
| `amount_paid` | `numeric` |  Nullable |
| `amount_due` | `numeric` |  Nullable |
| `is_current` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `attendance`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `member_id` | `int8` |  |
| `attendance_date` | `date` |  |
| `created_at` | `timestamp` |  Nullable |

## Table `payments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `member_id` | `int8` |  |
| `member_plan_id` | `int8` |  Nullable |
| `amount` | `numeric` |  |
| `payment_date` | `date` |  |
| `created_at` | `timestamp` |  Nullable |

## Table `expenses`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `title` | `varchar` |  |
| `amount` | `numeric` |  |
| `is_recurring` | `bool` |  Nullable |
| `recurrence_type` | `varchar` |  Nullable |
| `expense_date` | `date` |  |
| `created_at` | `timestamp` |  Nullable |

## Table `subscriptions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `plan_name` | `varchar` |  Nullable |
| `start_date` | `date` |  Nullable |
| `expiry_date` | `date` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `billing_addresses`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  Unique |
| `billing_name` | `varchar` |  Nullable |
| `address` | `text` |  Nullable |
| `gst_number` | `varchar` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `member_status_history`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `gym_id` | `int8` |  |
| `member_id` | `int8` |  |
| `old_status` | `varchar` |  Nullable |
| `new_status` | `varchar` |  Nullable |
| `changed_at` | `timestamp` |  Nullable |

