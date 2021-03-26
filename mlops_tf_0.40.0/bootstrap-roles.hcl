// This roles bootstrap file mirrors the default settings roles in the DB.

default {
    allow = ALL_OPERATIONS
    deny = [LIST_ALL_PROJECTS]
}

role "Reader" {
    allow = [
        DOWNLOAD_ARTIFACT,
        GET_PROJECT,
        LIST_PROJECTS,
        LIST_PROJECT_EVENTS,
        LIST_PROJECT_SHARINGS,
        LIST_ROLES,
        GET_ARTIFACT,
        LIST_ENTITY_ARTIFACT,
        GET_COMMENT,
        GET_DATASET,
        LIST_DATASETS,
        GET_DEPLOYMENT_ENVIRONMENT,
        LIST_DEPLOYMENT_ENVIRONMENTS,
        GET_DEPLOYMENT,
        LIST_DEPLOYMENTS,
        GET_EXPERIMENT,
        LIST_EXPERIMENTS,
        COUNT_EXPERIMENTS,
        LIST_EXPERIMENT_COMMENTS,
        LIST_EXPERIMENT_METRICS,
        LIST_TAGS,
        GET_USER,
        GET_USER_BY_USERNAME,
        LIST_USERS,
    ]
}
