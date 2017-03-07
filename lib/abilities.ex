defimpl Canada.Can, for: Atom do
  alias Pxblog.User
  alias Pxblog.Role
  alias Pxblog.Post
  alias Pxblog.Comment

  # When the user is not logged in, all they can do is read Posts and Comments
  def can?(nil, action, Post) when action in [:index], do: true
  def can?(nil, action, %Post{}) when action in [:show], do: true
  def can?(nil, action, Post) when action in [:new, :create], do: false
  def can?(nil, action, %Post{}) when action in [:edit, :update, :delete], do: false
  def can?(nil, _, _), do: false
end

defimpl Canada.Can, for: Pxblog.User do
  alias Pxblog.User
  alias Pxblog.Role
  alias Pxblog.Post
  alias Pxblog.Comment
    
  # abilities for blog posts
  def can?(user, action, Post) when action in [:index], do: true
  def can?(user, action, %Post{}) when action in [:show], do: true
  def can?(user, action, Post) when action in [:new, :create] do
    user.role.admin == true
  end
  def can?(user, action, %Post{}) when action in [:edit, :update, :delete] do
    user.role.admin == true
  end

  # abilities for blog comments
  def can?(user, action, Comment) when action in [:create], do: true
  def can?(user, action, %Comment{ user_id: user_id }) when action in [:delete] do
    user.role.admin || user.id == user_id
  end

  # abilities for users management
  def can?(user, _, User), do: user.role.admin
  def can?(user, _, %User{}), do: user.role.admin

  # fall back ability
  def can?(user, _, _), do: true
end
