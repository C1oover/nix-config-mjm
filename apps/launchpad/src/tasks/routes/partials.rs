use chrono::Utc;
use chrono_humanize::HumanTime;
use maud::{html, Markup};

use crate::tasks::{Reminder, Task};

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
            }
        }
    }
}

pub fn new_task_modal() -> Markup {
    html! {
        #new-task-modal
            .modal .fade
            aria-hidden="true"
            aria-labelledby="new-task-modal-title"
            tabindex="-1" {

            .modal-dialog .modal-fullscreen-md-down {
                .modal-content {
                    form
                        hx-post="/tasks"
                        hx-target="#task-list" {
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
}

pub fn new_reminder_modal() -> Markup {
    let remind_at = Utc::now().format("%Y-%m-%dT%H:%M");

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
                        hx-target="#reminder-list" {
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
                                    value=(remind_at);
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
                                input
                                    #new-reminder-repeat-interval
                                    .form-control
                                    name="repeat_interval"
                                    type="text"
                                    value=""
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
}
