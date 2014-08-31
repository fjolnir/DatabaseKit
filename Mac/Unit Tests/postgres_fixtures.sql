BEGIN;

DROP TABLE IF EXISTS "animals";
CREATE TABLE "animals" ("id" SERIAL PRIMARY KEY, "species" text, "nickname" text, "modelId" int4);

INSERT INTO "animals"("species", "nickname", "modelId") VALUES ('cat', 'awesome', '1');
INSERT INTO "animals"("species", "nickname", "modelId") VALUES ('dog', 'lame', '1');


DROP TABLE IF EXISTS "animals_people";
CREATE TABLE "animals_people" ("animalId" int4, "personId" int4);

INSERT INTO "animals_people" VALUES ('1', '3');


DROP TABLE IF EXISTS "belgians";
CREATE TABLE "belgians" ("id" SERIAL PRIMARY KEY,"nickname" text,"personId" int4);

INSERT INTO "belgians"("nickname", "personId") VALUES ('denis', '1');
INSERT INTO "belgians"("nickname", "personId") VALUES ('chucker', '1');


DROP TABLE IF EXISTS "foo";
CREATE TABLE "foo" ("id" SERIAL PRIMARY KEY, "bar" text, "baz" text, "integer" int4);

INSERT INTO "foo"("bar", "baz", "integer") VALUES ('foobarbaz', 'bazbazb', '1337');
INSERT INTO "foo"("bar", "baz", "integer") VALUES ('fjolnir', 'asgeirsson', '1601');


DROP TABLE IF EXISTS "models";
CREATE TABLE "models" ("id" SERIAL PRIMARY KEY, "name" text, "info" text);

INSERT INTO "models"("name", "info") VALUES ('a name', 'some info!');
INSERT INTO "models"("name", "info") VALUES ('another name', 'some more info!');


DROP TABLE IF EXISTS "people";
CREATE TABLE "people" ("id" SERIAL PRIMARY KEY, "userName" text, "realName" text, "modelId" int4);

INSERT INTO "people"("userName", "realName", "modelId") VALUES ('aptiva', 'fjolnir asgeirsson', '1');
INSERT INTO "people"("userName", "realName", "modelId") VALUES ('god', 'steve wozniak', '1');
INSERT INTO "people"("userName", "realName", "modelId") VALUES ('co-god', 'steve jobs', '0');

COMMIT;
