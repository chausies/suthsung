// Generated by CoffeeScript 2.5.1
(function() {
  // Create needed constants
  var bodyInput, db, form, list, submitBtn, titleInput;

  list = document.querySelector('ul');

  titleInput = document.querySelector('#title');

  bodyInput = document.querySelector('#body');

  form = document.querySelector('form');

  submitBtn = document.querySelector('form button');

  db = void 0;

  window.onload = function() {
    var addData, displayData, request;
    request = window.indexedDB.open('notes_db', 1);
    // onerror handler signifies the database didn't open successfully
    request.onerror = function() {
      console.log('Database failed to open');
    };
    // onsuccess handler signifies that the database opened successfully
    request.onsuccess = function() {
      console.log('Database opened successfully');
      // Store the opened database object in the db variable. 
      db = request.result;
      // Run the displayData() func to display the notes already in the IDB
      displayData();
    };
    // Setup database if necessary
    request.onupgradeneeded = function(e) {
      var objectStore;
      // Grab reference to the opened database
      db = e.target.result;
      // Create an objectStore to store notes in, including auto-incrementing
      // key
      objectStore = db.createObjectStore('notes_os', {
        keyPath: 'id',
        autoIncrement: true
      });
      // Define what data items the objectStore will contain
      objectStore.createIndex('title', 'title', {
        unique: false
      });
      objectStore.createIndex('body', 'body', {
        unique: false
      });
      console.log('Database setup complete');
    };
    addData = function(e) {
      var newItem, objectStore, transaction;
      // prevent normal submission behavior that refreshes page
      e.preventDefault();
      newItem = {
        title: titleInput.value,
        body: bodyInput.value
      };
      // open a read/write db transaction, ready for adding the data
      transaction = db.transaction(['notes_os'], 'readwrite');
      // call an object store that's already been added to the database
      objectStore = transaction.objectStore('notes_os');
      // Make a request to add our newItem object to the object store
      request = objectStore.add(newItem);
      request.onsuccess = function() {
        // Clear the form, ready for adding the next entry
        titleInput.value = '';
        bodyInput.value = '';
        console.log('asdf req success');
      };
      // Report on the success of the transaction completing, when everything
      // is done
      transaction.oncomplete = function() {
        console.log('Transaction completed: database modiciation finished.');
        // Update the display of data
        displayData();
      };
      transaction.onerror = function() {
        console.log('Transaction not opened due to error');
      };
    };
    // Create an onsubmit handler so addData() is run when form submitted
    form.onsubmit = addData;
    return displayData = function() {
      var deleteItem, objectStore;
      // Empty the list
      while (list.firstChild) {
        list.removeChild(list.firstChild);
      }
      // Access the object store, and then obtain a cursor that iterates
      // through everything in there
      objectStore = db.transaction('notes_os').objectStore('notes_os');
      objectStore.openCursor().onsuccess = function(e) {
        var cursor, deleteBtn, h3, listItem, para, v;
        cursor = e.target.result;
        // If there is still another data item to iterate through, run this
        if (cursor) {
          listItem = document.createElement('li');
          h3 = document.createElement('h3');
          para = document.createElement('p');
          listItem.appendChild(h3);
          listItem.appendChild(para);
          list.appendChild(listItem);
          v = cursor.value;
          h3.textContent = v.title;
          para.textContent = v.body;
          listItem.setAttribute('data-node-id', v.id);
          deleteBtn = document.createElement('button');
          listItem.appendChild(deleteBtn);
          deleteBtn.textContent('Delete');
          deleteBtn.onclick = deleteItem;
          cursor.continue();
        } else {
          if (!list.firstChild) {
            listItem = document.createElement('li');
            listItem.textContent = 'No notes stored.';
            list.appendChild(listItem);
          } else {
            console.log('Notes all displayed!');
          }
        }
      };
      return deleteItem = function(e) {
        var noteId, transaction;
        // Get node id, and convert to number to be used to index IDB. IDB key
        // values are type-sensitive
        noteId = Number(e.target.parentNode.getAttribute('data-node-id'));
        transaction = db.transaction(['notes_os'], 'readwrite');
        objectStore = transaction.objectStore('notes_os');
        request = objectStore.delete(noteId);
        transaction.oncomplete = function() {
          var listItem, pn;
          pn = e.target.parentNode;
          pn.parentNode.removeChild(pn);
          console.log('Note ' + noteId + ' deleted.');
          // if list empty, display that no notes stored
          if (!list.firstChild) {
            listItem = document.createElement('li');
            listItem.textContent = 'No notes stored.';
            list.appendChild(listItem);
          }
        };
      };
    };
  };

}).call(this);
