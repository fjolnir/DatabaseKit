BEGIN TRANSACTION;
DROP TABLE IF EXISTS foo;
CREATE TABLE foo ("UUID" UUID_BLOB PRIMARY KEY NOT NULL, "bar" TEXT DEFAULT NULL, "baz" TEXT DEFAULT NULL, "integer" INTEGER DEFAULT NULL);
INSERT INTO "foo" VALUES(X'B89BD574493942E1B011CA8688D776CD','foobarbaz','bazbazb',1337);
INSERT INTO "foo" VALUES(X'87EE3C503C294F8B827375F93DAF7B12','fjolnir','asgeirsson',1601);
COMMIT;