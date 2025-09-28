$(function () {
  $("form.delete").on("submit", function (event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");
    if (!ok) return;

    var form = $(this);

    $.ajax({
      url: form.attr("action"),
      method: form.attr("method"),
      headers: { "X-Requested-With": "XMLHttpRequest" }
      // no data needed for this route; Content-Length: 0 is fine
    })
      .done(function (_data, _textStatus, _jqXHR) {
        form.parent("li").remove();
      })
      .fail(function (_jqXHR) {
        alert("Sorry, something went wrong deleting that item.");
      });
  });
});
