$(() => {
  window.DecidimCensusConnector = window.DecidimCensusConnector || {};

  window.DecidimCensusConnector.verificationCensusInitialize = () => {
    const $documentType = $("#data_handler_document_type");
    if ($documentType.length > 0) {
      const $documentScope = $("#document_scope_selector");
      const toggleDocumentScope = () => {
        if ($documentType.val()=="passport") {
          $documentScope.show();
        } else {
          $documentScope.hide();
        }
      }
      toggleDocumentScope();
      $documentType.on('change', toggleDocumentScope);
    }

    const $addressScope = $("#data_handler_address_scope_id");
    if ($addressScope.length > 0) {
      const $scope = $("#scope_selector");
      const $hidden = $("input[type=hidden]", $addressScope);
      const localScopeRanges = $addressScope.parent().data("localScopeRanges");
      const toggleScope = () => {
        const addressScopeId = $hidden.val();
        if (localScopeRanges.some(range => range[0] <= addressScopeId && addressScopeId <= range[1])) {
          $scope.hide();
        } else {
          $scope.show();
        }
      }
      toggleScope();
      $hidden.on('change', toggleScope);
    }

    const $documentUploader = $(".document_uploader input[type=file]");
    if ($documentUploader.length > 0) {
      const showImage = (changeEvent) => {
        const reader = new FileReader();
        const $image = $("img", $(changeEvent.target).parents(".document_uploader"));
        reader.onload = (loadEvent) => {
          $image.attr('src', loadEvent.target.result);
        }
        reader.readAsDataURL(changeEvent.target.files[0]);
      }
      $documentUploader.on('change', showImage);
    }
  };

  window.DecidimCensusConnector.verificationCensusInitialize();
});
