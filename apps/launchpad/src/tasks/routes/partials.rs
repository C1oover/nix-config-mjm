use chrono::Utc;
use chrono_humanize::HumanTime;
use chrono_tz::Tz;
use maud::{html, Markup, PreEscaped};

use crate::tasks::{Reminder, Task};

pub fn hide_modal(id: &str) -> Markup {
    html! {
        script type="text/javascript" {
            (PreEscaped(format!(r##"
                bootstrap.Modal.getInstance("#{}").hide();
            "##, id)))
        }
    }
}

pub fn task_list(tasks: &[Task]) -> Markup {
    html! {
        @for task in tasks {
            li .list-group-item .d-flex .justify-content-between .align-items-start {
                input
                    #{ "task-check-" (task.id) }
                    .form-check-input
                    .me-2
                    type="checkbox"
                    value=""
                    checked[task.is_completed()]
                    autocomplete="off"
                    hx-post={ "/tasks/" (task.id) "/toggle"}
                    hx-target="#task-list";

                div .me-auto {
                    label
                        .form-check-label
                        .me-auto
                        .text-secondary-emphasis[task.is_completed()]
                        .text-decoration-line-through[task.is_completed()]
                        for={ "task-check-" (task.id) } {
                        (task.description)
                    }

                    @if !task.is_completed() {
                        @if let Some(notify_at) = task.notify_at {
                            div {
                                small .text-body-secondary {
                                    "Snoozed until "
                                    (HumanTime::from(notify_at))
                                }
                            }
                        }
                    }

                    @if !task.tags.is_empty() {
                        div {
                            @for tag in &task.tags {
                                span .badge .text-bg-secondary .me-1 {
                                    (tag)
                                }
                            }
                        }
                    }
                }

                a .btn.btn-primary.btn-sm href={ "/tasks/" (task.id) "/edit" } {
                    "Edit"
                }
            }
        }
    }
}

pub fn reminder_list(reminders: &[Reminder]) -> Markup {
    html! {
        @for reminder in reminders {
            li
                .list-group-item
                .d-flex.justify-content-between.align-items-start
                .bg-info-subtle[reminder.is_firing()] {

                .me-auto {
                    (reminder.description)

                    div {
                        small .text-body-secondary {
                            @if reminder.is_firing() {
                                "Firing since "
                            }
                            (HumanTime::from(reminder.remind_at))
                        }
                    }

                    @if !reminder.tags.is_empty() {
                        div {
                            @for tag in &reminder.tags {
                                span .badge .text-bg-secondary .me-1 {
                                    (tag)
                                }
                            }
                        }
                    }
                }

                a .btn.btn-primary.btn-sm href={ "/reminders/" (reminder.id) "/edit" } {
                    "Edit"
                }
            }
        }
    }
}

pub fn modal_container(id: &str, body: Markup) -> Markup {
    html! {
        #(id)
            .modal .fade
            aria-hidden="true"
            aria-labelledby={(id) "-title"}
            tabindex="-1"
            "hx-on::before-cleanup-element"="console.log('disposing'); bootstrap.Modal.getInstance(this).dispose()" {
            (body)
        }
    }
}

pub fn new_task_modal() -> Markup {
    html! {
        .modal-dialog .modal-fullscreen-md-down {
            .modal-content {
                form
                    hx-post="/tasks"
                    hx-target="#new-task-modal" {

                    .modal-header {
                        h1 #new-task-modal-title .modal-title .fs-5 {
                            "New task"
                        }
                        button .btn-close type="button" data-bs-dismiss="modal" aria-label="Close" {}
                    }
                    .modal-body {
                        .mb-3 {
                            label .form-label for="new-task-description" { "Description" }
                            input
                                #new-task-description
                                .form-control
                                name="description"
                                type="text"
                                autocomplete="off";
                        }

                        .mb-3 {
                            label .form-label for="new-task-tags" { "Tags" }
                            input
                                #new-task-tags
                                .form-control
                                name="tags"
                                type="text"
                                autocomplete="off";
                        }
                    }
                    .modal-footer {
                        button .btn.btn-secondary type="button" data-bs-dismiss="modal" { "Close" }
                        button .btn.btn-primary { "Save" }
                    }
                }
            }
        }
    }
}

pub fn new_reminder_modal(tz: &Tz) -> Markup {
    let remind_at = Utc::now().with_timezone(tz).format("%Y-%m-%dT%H:%M");

    html! {
        #new-reminder-modal
            .modal .fade
            aria-hidden="true"
            aria-labelledby="new-reminder-modal-title"
            tabindex="-1" {

            .modal-dialog .modal-fullscreen-md-down {
                .modal-content {
                    form
                        hx-post="/reminders"
                        hx-target="#new-reminder-modal"
                        hx-swap="outerHTML" {

                        .modal-header {
                            h1 #new-reminder-modal-title .modal-title .fs-5 {
                                "New reminder"
                            }
                            button .btn-close type="button" data-bs-dismiss="modal" aria-label="Close" {}
                        }
                        .modal-body {
                            .mb-3 {
                                label .form-label for="new-reminder-description" { "Description" }
                                input
                                    #new-reminder-description
                                    .form-control
                                    name="description"
                                    type="text"
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-tags" { "Tags" }
                                input
                                    #new-reminder-tags
                                    .form-control
                                    name="tags"
                                    type="text"
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-remind-at" { "Remind at" }
                                input
                                    #new-reminder-remind-at
                                    .form-control
                                    name="remind_at"
                                    type="datetime-local"
                                    value=(remind_at)
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-snooze-minutes" { "Snooze minutes" }
                                input
                                    #new-reminder-snooze-minutes
                                    .form-control
                                    name="snooze_minutes"
                                    type="number"
                                    value="10"
                                    autocomplete="off";
                            }

                            .mb-3 {
                                label .form-label for="new-reminder-repeat-interval" { "Repeat every" }

                                .row {
                                    .col-sm .mb-2 {
                                        .input-group {
                                            input
                                                #new-reminder-repeat-days
                                                .form-control
                                                name="repeat_days"
                                                type="number"
                                                autocomplete="off";

                                            span .input-group-text { "days" }
                                        }
                                    }

                                    .col-sm .mb-2 {
                                        .input-group {
                                            input
                                                #new-reminder-repeat-weeks
                                                .form-control
                                                name="repeat_weeks"
                                                type="number"
                                                autocomplete="off";

                                            span .input-group-text { "weeks" }
                                        }
                                    }

                                    .col-sm .mb-2 {
                                        .input-group {
                                            input
                                                #new-reminder-repeat-months
                                                .form-control
                                                name="repeat_months"
                                                type="number"
                                                autocomplete="off";

                                            span .input-group-text { "months" }
                                        }
                                    }
                                }
                            }
                        }
                        .modal-footer {
                            button .btn.btn-secondary type="button" data-bs-dismiss="modal" { "Close" }
                            button .btn.btn-primary { "Save" }
                        }
                    }
                }
            }
        }
    }
}
