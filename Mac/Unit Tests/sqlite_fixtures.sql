BEGIN TRANSACTION;
DROP TABLE IF EXISTS foo;
CREATE TABLE foo ("identifier" VARCHAR(36) PRIMARY KEY NOT NULL, "bar" varchar(255) DEFAULT NULL, "baz" TEXT DEFAULT NULL, "integer" integer DEFAULT NULL);
INSERT INTO "foo" VALUES(1,'foobarbaz','bazbazb',1337);
INSERT INTO "foo" VALUES(2,'fjolnir','asgeirsson',1601);
COMMIT;