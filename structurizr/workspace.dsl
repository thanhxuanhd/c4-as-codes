workspace {

    model {
        # Actor
        publicUser = person "Public User" "" "User" {
            tags "Microsoft Azure - Users"
        }
        authorizedUser = person "Authorized User" "" "User" {
            tags "Microsoft Azure - Users"
        }
        developer = person "Developer" "" "User" {
            tags "Microsoft Azure - Users"
        }

        authorizationSystem = softwareSystem "Authorization System" "For authorization purposes" "External System" {
            tags "Microsoft Azure - External Identities"
        }
        publisherSystem = softwareSystem "Publisher System" "Giving details about books published by them" "External System" {
            tags "Microsoft Azure - External Identities"
        }

        application = group "Application" {
            # Book Strore System
                bookStoreSystem = softwareSystem "Book Strore System" "" "App" {  
                tags "Microsoft Azure - Enterprise Applications"       
                bookstore = group "Application" {
                    searchWebAPI = container "Search Web API" "Developed with Go" "" "Api" {
                        tags "Microsoft Azure - API Management Services"
                    }
                    adminWebAPI = container "Admin Web API" "Developed with Go" "" "Api" {
                        tags "Microsoft Azure - API Management Services"
                        serviceBook = component "[service.Boook]" "" "" "service"
                        serviceAuthorizer = component "[service.Authorizer]" "" "" "service"
                        serviceEventsPublisher = component "[service.EventsPublisher]" "It publishes books-related events to Events Publisher" "" "service"
                    }
                    publicWebAPI = container "Public Web API" "" "" "Api" {
                        tags "Microsoft Azure - API Management Services"
                    }
                    elasticSearchEventsConsumer = container "ElasticSearch Events Consumer" "Developed with Go" "" "Api" {
                        tags "Microsoft Azure - On Premises Data Gateways"
                    }
                    searchDatabase = container "Elastic" "Elastic Search Database" "" "Database" {
                        tags "Microsoft Azure - Cognitive Search"
                    }
                    postgreSQLDatabase = container "postgreSQL" "Read/Write Relational Database Stores books detail" "" "Database" {
                        tags "Microsoft Azure - Azure Database PostgreSQL Server"
                    }
                    readerCache = container "Reader Cache: Caches books details" "Memcached" "" "Database" {
                        tags "Microsoft Azure - Managed Database"
                    }
                    publisherRecurrentUpdate = container "Publisher Recurrent Update" "" "" "Api" {
                        tags "Microsoft Azure - API Management Services"
                    }
                }

                bookKafkaSystem = container "Book Kafka System" "Apache Kafka 3.0" "Handles book-related domain events" "External System" {
                    tags "Microsoft Azure - External Identities"
                }
            }

            # Relationship
            publicUser -> bookStoreSystem "Public User"
            bookStoreSystem -> authorizationSystem  "External Authorization System for authorization purposes"
        
            # Level 2
            searchWebAPI -> searchDatabase "Use ElasticSearch as the Search Database for searching read-only records" {
                tags "Https Request"
            }

            adminWebAPI -> postgreSQLDatabase "Read data from and write data to Read/Write Relational Database"
            adminWebAPI -> bookKafkaSystem "Publishes Events to external Books Kafka container"
            adminWebAPI -> publisherRecurrentUpdate "It uses the Admin Web API for updating that data"
            adminWebAPI -> authorizationSystem "Authorized by external Authorization System."

            publicWebAPI -> postgreSQLDatabase "It reads data from Read/Write Relational Database"
            publicWebAPI -> readerCache "It reads/write data to Reader Cache database"

            publicUser -> publicWebAPI "Allows Public users getting books detail"

            authorizedUser -> searchWebAPI "Allows only authorized users searching books records via HTTPs handlers" {
                tags "Https Request"
            }
            authorizedUser -> adminWebAPI "Allows only authorized users administering books details via HTTP handlers" {
                tags "Http Request"
            }

            # authorizedUser -> authorizationSystem "Authorized user"

            bookKafkaSystem -> elasticSearchEventsConsumer "Listening to Kafka domain events and write publisher to Search Database for updating"
            elasticSearchEventsConsumer -> searchDatabase "Write publisher to Search Database for updating"

            publisherRecurrentUpdate -> publisherSystem "Listening to external events coming from Publisher System"
            publisherRecurrentUpdate -> postgreSQLDatabase "Updates the Read/Write Relational Database with detail from Publisher system"
            publisherRecurrentUpdate -> bookKafkaSystem "Kafka"

            # Level 3
            authorizedUser -> serviceBook "Allow administering books details"
            serviceBook -> serviceAuthorizer "Authorizes books detail by Authorization Servic"
            serviceAuthorizer -> authorizationSystem "Authorization Service allows authorizing users by using external Authorization System"
            serviceEventsPublisher -> bookKafkaSystem "Events Publisher publishes books-related domain events to externa Books Kafka container"
            serviceBook -> postgreSQLDatabase "Read form and write data to Read/Write Relational Database"
            serviceBook -> serviceEventsPublisher "It publishes books-related events to Events Publisher"
        }

        deploymentStep = softwareSystem "deploymentStep" "Workflow CI/CD for deploying" {
            repository = container "Repository" "" "" "deployment" {
                tags "Microsoft Azure - Code"
            }
            codePipeline = container "CodePipeline" "" "" "deployment" {
                tags "Microsoft Azure - Builds"
            }
            codeBuild = container "CodeBuild" "" "" "deployment" {
                tags "Microsoft Azure - Builds"
            }
            amazonECR = container "Amazon ECR" "" "" "deployment" { 
                tags "Microsoft Azure - Community Images"
            }
            amazonEKS = container "Amazon EKS" "" "" "deployment" {
                tags "Microsoft Azure - Azure Deployment Environments"
            }

            developer -> repository "Developer commit and push changes to a source code repository."
            codePipeline -> repository "Downloads the source code and starts the build process"
            codePipeline -> codeBuild "downloads the necessary source files and starts running commands to build and tag a local Docker container image"
            codeBuild -> amazonECR "Pushes the container image to Amazon ECR"
            codeBuild -> amazonEKS "CodeBuild deploys image on Amazon EKS"
        }

        ## Deployment for Dev Env
        deploymentEnvironment "MicroservicesDeployment" {
            deploymentNode "BOOKS STORE SYSTEM" "" "AWS EKS" {       
                deploymentNode "Docker Container - Web Server" "" "Docker" {
                    deploymentNode "AWS EKS" "" "" {
                        containerInstance adminWebAPI
                        containerInstance searchWebAPI
                        containerInstance publicWebAPI
                    }
                }
                deploymentNode "PostgreSQL Read/Write Relational Database" "" "" {
                    deploymentNode "AWS RDS" "" "" {
                        containerInstance postgreSQLDatabase
                    }
                }
                deploymentNode "Elastic Search Database - Database Server" "" "Elastic Search Database" {
                    deploymentNode "AWS OpenSearch" "" {
                        containerInstance searchDatabase
                    }
                }

                deploymentNode "ElasticSearch Events Consumer" "" "" {
                    deploymentNode "EC2-b as a micro-service" "" {
                        containerInstance elasticSearchEventsConsumer
                    }
                }

                deploymentNode "Reader Cache" "" "" {
                    deploymentNode "AWS ElastiCache" "" {
                        containerInstance elasticSearchEventsConsumer
                    }
                }
            }
        }
    }

    views {
        systemContext bookStoreSystem "Level1" {
            include *
            autoLayout
        }

        container bookStoreSystem "Container" {
            include *
            autoLayout
        }

        component adminWebAPI "ServiceBook" {
            include *
            autoLayout
        }

        # component deploymentStep "deploymentStep" {
        #     include *
        #     autoLayout
        # }

        deployment bookStoreSystem "MicroservicesDeployment" "AWS-DEV" "Microservices Deployment" {
            include *           
            autoLayout
        }

        dynamic deploymentStep "Workflow" {
            title "Workflow CI/CD for deploying"
            developer -> repository "Developer commit and push changes to a source code repository"
            repository -> codePipeline "A webhook on the code repository triggers a CodePipeline build in the AWS Cloud"
            codePipeline -> repository "Downloads the source code and starts the build process"
            codePipeline -> codeBuild "Downloads the necessary source files and starts running commands to build and tag a local Docker container image"
            codeBuild -> amazonECR "pushes the container image to Amazon ECR." 
            codeBuild -> amazonEKS "CodeBuild deploys image on Amazon EKS"
            autoLayout
        }


        styles { 
            element "User" {
                background white
                border dashed
                stroke #1a83dc
            }
            element person {
                background white
            }
            element "External System" {
                background white
                border dashed
            }
            relationship "Relationship" {
                dashed false
            }
            relationship "Https Request" {
                dashed true
                color green
            }
            relationship "Http Request" {
                dashed true
                color blue
            }
            element "Database" {
                background white
                color #50e6ff
                stroke #0078d4
                shape Cylinder
            }
            element "App"{
                background white
                stroke #0078d4
            }
            element "Api" {
                background white
                border solid
                stroke #0078d4
            }
            element "deployment" {
                background white
                border dashed
                color #50e6ff
                stroke #1a83dc
            }
            element "service" {
                background white
                border dashed
                stroke #1a83dc
                color #1a83dc
            }
        }

        themes https://static.structurizr.com/themes/microsoft-azure-2023.01.24/theme.json
    }
}