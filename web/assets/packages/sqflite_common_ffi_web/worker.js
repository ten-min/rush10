// Web worker for SQLite operations
self.importScripts('sqlite3.js');

let db = null;

self.onmessage = async function(e) {
  const data = e.data;
  
  try {
    switch (data.action) {
      case 'open':
        if (!db) {
          const sqlite3 = await self.sqlite3InitModule();
          db = new sqlite3.Database();
        }
        self.postMessage({ id: data.id, result: true });
        break;
        
      case 'execute':
        if (!db) {
          throw new Error('Database not opened');
        }
        const stmt = db.prepare(data.sql);
        const result = data.params ? stmt.run(data.params) : stmt.run();
        stmt.finalize();
        self.postMessage({ id: data.id, result });
        break;
        
      case 'query':
        if (!db) {
          throw new Error('Database not opened');
        }
        const queryStmt = db.prepare(data.sql);
        const rows = data.params ? queryStmt.all(data.params) : queryStmt.all();
        queryStmt.finalize();
        self.postMessage({ id: data.id, result: rows });
        break;
        
      case 'close':
        if (db) {
          db.close();
          db = null;
        }
        self.postMessage({ id: data.id, result: true });
        break;
        
      default:
        throw new Error('Unknown action: ' + data.action);
    }
  } catch (error) {
    self.postMessage({ id: data.id, error: error.message });
  }
}; 