// Import the socket library
import {Socket} from "phoenix"

// Grab the user's token and id from the meta tags
const userToken = $("meta[name='channel_token']").attr("content")
const currentUser = $("meta[name='current_user']").attr("content")
const adminUser = $("meta[name='admin_user']").attr("content") == "true"
// And make sure we're connecting with the user's token to persist the user id to the session
const socket = new Socket("/socket", {params: {token: userToken}})
// And connect out
socket.connect()

// Our actions to listen for
const CREATED_COMMENT  = "CREATED_COMMENT"
const DELETED_COMMENT  = "DELETED_COMMENT"

// REQ 1: Grab the current post's id from a hidden input on the page
const postId = $("#post-id").val()
const channel = socket.channel(`comments:${postId}`, {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

// REQ 2: Based on a payload, return to us an HTML template for a comment
// Consider this a poor version of JSX
const createComment = (payload) => `
  <div id="comment-${payload.commentId}" class="comment" data-comment-id="${payload.commentId}">
    <div class="media-body">
      <h4 class="media-heading">
        <small>by</small> 
        <strong class="comment-author">${payload.author}</strong>
        <small>at ${moment(payload.insertedAt).format("YYYY-MM-DD HH:mm")}</small>   
        ${ userToken && (adminUser || currentUser == payload.authorId) ? '<div class="pull-right"><small><a href="#" class="delete"><i class="glyphicon glyphicon-remove"></i> Delete</a></small></div>' : '' }      
      </h4>
      <div class="comment-body">${payload.body}</div>
      <hr>
    </div>
  </div>
`
// REQ 3: Provide the comment's body from the form
const getCommentBody     = () => $("#comment_body").val()
// REQ 4: Based on something being clicked, find the parent comment id
const getTargetCommentId = (target) => $(target).parents(".comment").data("comment-id")
// REQ 5: Reset the input fields to blank
const resetFields = () => {
  $("#comment_body").val("")
}

// REQ 6: Push the CREATED_COMMENT event to the socket with the appropriate author/body
$(".create-comment").on("click", (event) => {
  event.preventDefault()
  channel.push(CREATED_COMMENT, { body: getCommentBody(), postId })
  resetFields()
})

// REQ 7: Push the DELETED_COMMENT event to the socket but only pass the comment id (that's all we need)
$(".comments").on("click", ".delete", (event) => {
  event.preventDefault()

  if (confirm("Are you sure?")) {
    const commentId = getTargetCommentId(event.currentTarget)
    channel.push(DELETED_COMMENT, { commentId, postId })
  }
})

// REQ 8: Handle receiving the CREATED_COMMENT event
channel.on(CREATED_COMMENT, (payload) => {
  // Add it to the DOM using our handy template function
  $(".comments h3").after(
    createComment(payload)
  )
})

// REQ 9: Handle receiving the DELETED_COMMENT event
channel.on(DELETED_COMMENT, (payload) => {
  // Just delete the comment from the DOM
  $(`#comment-${payload.commentId}`).remove()
})

export default socket
