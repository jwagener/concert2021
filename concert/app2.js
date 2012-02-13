// Get a reference to the root of the chat data.
//var bobRef = concertRef.append('bob');
//bobRef.set('position');

//bobRef.on('child_added', function(callbackData) {
  
//});
 // We use on('child_added') to be notified when new children objects are added to the chat.
/* chatMessagesPath.on('child_added', function(childSnapshot) {
   // childSnapshot is the added object.  We'll extract the value and use it to append to
   // our messagesDiv.
   var message = childSnapshot.val();

   $("#messagesDiv").append("<em>" + message.name + "</em>: " + message.text + "<br />");
   $('#messagesDiv')[0].scrollTop = $('#messagesDiv')[0].scrollHeight;
 });*/

 // When the user presses enter on the message input, add the chat message to our firebase data.
 $("#messageInput").keypress(function (e) {
   if (e.keyCode == 13) {
     // Push a new object onto chatMessagesPath with the name/text that the user entered.
     chatMessagesPath.push({
       name:$("#nameInput").val(),
       text:$("#messageInput").val()
     });
     $("#messageInput").val("");
   }
 });