define(function(require) {
  var Sunstone = require('sunstone');
  var Notifier = require('utils/notifier');
  var Locale = require('utils/locale');
  var DataTable = require('./datatable');
  var OpenNebulaZone = require('opennebula/zone');

  var TAB_ID = require('./tabId');
  var CREATE_DIALOG_ID = require('./dialogs/create/dialogId');

  var _actions = {
    "Zone.create" : {
      type: "create",
      call: OpenNebulaZone.create,
      callback: function(request, response) {
        Sunstone.getDialog(CREATE_DIALOG_ID).hide();
        Sunstone.getDialog(CREATE_DIALOG_ID).reset();
        Sunstone.getDataTable(TAB_ID).addElement(request, response);
      },
      error: Notifier.onError,
      notify: true
    },

    "Zone.create_dialog" : {
      type: "custom",
      call: function() {
        Sunstone.getDialog(CREATE_DIALOG_ID).show();
      }
    },

    "Zone.list" : {
      type: "list",
      call: OpenNebulaZone.list,
      callback: function(request, response) {
        Sunstone.getDataTable(TAB_ID).updateView(request, response);
      },
      error: Notifier.onError
    },

    "Zone.show" : {
      type: "single",
      call: OpenNebulaZone.show,
      callback: function(request, response) {
        Sunstone.getDataTable(TAB_ID).updateElement(request, response);
        if (Sunstone.rightInfoVisible($('#'+TAB_ID))) {
          Sunstone.insertPanels(TAB_ID, response);
        }
      },
      error: Notifier.onError
    },

    "Zone.show_to_update" : {
      type: "single",
      call: OpenNebulaZone.show,
      // TODO callback: fillPopPup,
      error: Notifier.onError
    },

    "Zone.refresh" : {
      type: "custom",
      call: function() {
        var tab = $('#' + TAB_ID);
        if (Sunstone.rightInfoVisible(tab)) {
          Sunstone.runAction("Zone.show", Sunstone.rightInfoResourceId(tab))
        } else {
          Sunstone.getDataTable(TAB_ID).waitingNodes();
          Sunstone.runAction("Zone.list", {force: true});
        }
      },
      error: Notifier.onError
    },

    "Zone.delete" : {
      type: "multiple",
      call : OpenNebulaZone.del,
      callback : function(request, response) {
        Sunstone.getDataTable(TAB_ID).deleteElement(request, response);
      },
      elements: function() {
        return Sunstone.getDataTable(TAB_ID).elements();
      },
      error : Notifier.onError,
      notify:true
    },

    "Zone.update_template" : {  // Update template
      type: "single",
      call: OpenNebulaZone.update,
      callback: function(request, response) {
        Notifier.notifyMessage(Locale.tr("Zone updated correctly"));
        Sunstone.runAction('Zone.show', request.request.data[0][0]);
      },
      error: Notifier.onError
    },

    "Zone.fetch_template" : {
      type: "single",
      call: OpenNebulaZone.fetch_template,
      callback: function(request, response) {
        $('#template_update_dialog #template_update_textarea').val(response.template);
      },
      error: Notifier.onError
    },

    "Zone.rename" : {
      type: "single",
      call: OpenNebulaZone.rename,
      callback: function(request) {
        Notifier.notifyMessage(Locale.tr("Zone renamed correctly"));
        Sunstone.runAction('Zone.show', request.request.data[0][0]);
      },
      error: Notifier.onError,
      notify: true
    }
  };

  return _actions;
})
