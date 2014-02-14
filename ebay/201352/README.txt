This file is automatically copied to /httpd/static/ebay/$VERSION/README.txt from /httpd/servers/ebay2013/post-update/README.txt

1. Both eBay category tree and Recommended Item Specifics are packed into ebay.db sqlite3 file. Both for eBay.com (site=0) and eBay motors (site=100) (see 'ebay_sites' table). That's 44MB ebay.db file.

2. Categories are in "ebay_categories" table.
For Summer-2013 all ebay.com categories can accept custom (user defined) item specifics.

3. Recommended item specifics are in "ebay_specifics" table:

CREATE TABLE IF NOT EXISTS ebay_specifics (
  site int(10) NOT NULL DEFAULT 0,
  cid integer NOT NULL DEFAULT 0,
  json BLOB,
  PRIMARY KEY(site,cid)
);

json is a gzipped chunk of data (gzipped with Compress::Zlib::memGzip).
If you want to extract a raw json, use a perl script hook in this directory:
./get_json_from_db.pl <category id>

For example, for "Books / Fiction and Literature":
./get_json_from_db.pl 377

4. I think, that generating a single 44MB compressed db file every release is just better, than generating 16000 separate .json files and 30000+ nested directories (uncompressed 300-600MB total). Imagine how many files we'll have in a year - we'll drown! Imagine you need to move/backup these files from one host to another. Ha?

5. Let's just have one small database every release. And use "./get_json_from_db.pl catID > catID.json" hook if you need a .json chunk saved to the file.

6. Script that generates everything is in /httpd/servers/ebay2013/full_update_fast.pl. Raw eBay xml responses are in "xml" directory here (script gzips them, uncompressed they're about 600MB)

Email me for any questions: Taras I. <mispeaced@gmail.com>
