$(function() {
  // Fix bootstrap breaking the links with method delete
  $(document).off("click.bs.dropdown.data-api", ".dropdown form");

  $(".sign-out").on("click", function(event) {
    event.preventDefault();
    $("form#sign-out").submit();
  });
});
