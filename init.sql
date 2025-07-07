-- Initialize databases for Rails application
CREATE DATABASE gerege_idp_development_cache;
CREATE DATABASE gerege_idp_development_queue;
CREATE DATABASE gerege_idp_development_cable;

-- Grant privileges to postgres user
GRANT ALL PRIVILEGES ON DATABASE gerege_idp_development TO postgres;
GRANT ALL PRIVILEGES ON DATABASE gerege_idp_development_cache TO postgres;
GRANT ALL PRIVILEGES ON DATABASE gerege_idp_development_queue TO postgres;
GRANT ALL PRIVILEGES ON DATABASE gerege_idp_development_cable TO postgres; 