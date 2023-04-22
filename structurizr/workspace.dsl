workspace {

    model {
        # Actor
        publicUser = person "Public User" 
        authorizedUser = person "Authorized User"

        authorizationSystem = softwareSystem "Authorization System" "For authorization purposes" "External System"
        publisherSystem = softwareSystem "Publisher System" "Giving details about books published by them" "External System"

        application = group "Application" {
            # Book Strore System
                bookStoreSystem = softwareSystem "Book Strore System" {         
                bookstore = group "Application" {
                    searchWebAPI = container "Search Web API" "Developed with Go"
                    adminWebAPI = container "Admin Web API" "Developed with Go" {
                        serviceBook = component "[service.Boook]"
                        serviceAuthorizer = component "[service.Authorizer]"
                        serviceEventsPublisher = component "[service.EventsPublisher]" "It publishes books-related events to Events Publisher"
                    }
                    publicWebAPI = container "Public Web API"
                    elasticSearchEventsConsumer = container "ElasticSearch Events Consumer" "Developed with Go"
                    searchDatabase = container "Elastic" "Elastic Search Database" "Database"
                    postgreSQLDatabase = container "postgreSQL" "Read/Write Relational Database Stores books detail" "Database"
                    readerCache = container "Reader Cache: Caches books details" "Memcached" "Database"
                    publisherRecurrentUpdate = container "Publisher Recurrent Update"
                }

                bookKafkaSystem = container "Book Kafka System" "Apache Kafka 3.0" "Handles book-related domain events" "External System"
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

            elasticSearchEventsConsumer -> bookKafkaSystem "Listening to Kafka domain events and write publisher to Search Database for updating"

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

         # # Deployment for Dev Env
        deploymentEnvironment "MicroservicesDeployment" {
            deploymentNode "BOOKS STORE SYSTEM" "" "AWS EKS" {       
                deploymentNode "Docker Container - Web Server" "" "Docker" {
                    deploymentNode "Apache Tomcat" "" "" {
                        containerInstance adminWebAPI
                        containerInstance searchWebAPI
                    }
                }
                deploymentNode "Docker Container - Database Server" "" "Docker" {
                    deploymentNode "Database Server" "" "Postgre SQL" {
                        containerInstance postgreSQLDatabase
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

        deployment bookStoreSystem "MicroservicesDeployment" "AWS-DEV" "Microservices Deployment" {
            include *           
            autoLayout
        }


        styles {     
            element "External System" {
                background #999999
                color #ffffff
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
                shape Cylinder
            }
        }

        theme default
    }
}