// public/javascripts/application.js
$(function () {
  $("form.delete").on("submit", function (event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");
    if (!ok) return;

    var form = $(this);

    var request = $.ajax({
      url: form.attr("action"),
      method: form.attr("method"),
      headers: { "X-Requested-With": "XMLHttpRequest" }
    });

    request.done(function (data, textStatus, jqXHR) {
      if (jqXHR.status === 204) {
        // Successful AJAX deletion, no content returned
        form.parent("li").remove();
      } else if (jqXHR.status === 200) {
        // Server returned a redirect page
        document.location = data;
      }
    });

    request.fail(function (_jqXHR, _textStatus, _errorThrown) {
      alert("Sorry, something went wrong deleting that item.");
    });
  });
});
