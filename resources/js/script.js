
$(function  () {
  var adjustment
    $("ol.cts").sortable({
      group: 'cts',
      pullPlaceholder: false,
      // animation on drop
      onDrop: function  (item, targetContainer, _super) {
        var clonedItem = $('<li/>').css({height: 0})
        item.before(clonedItem)
        clonedItem.animate({'height': item.height()})
        
        item.animate(clonedItem.position(), function  () {
          clonedItem.detach()
          _super(item)
        })
      },
    
      // set item relative to cursor position
      onDragStart: function ($item, container, _super) {
        var offset = $item.offset(),
        pointer = container.rootGroup.pointer
    
        adjustment = {
          left: pointer.left - offset.left,
          top: pointer.top - offset.top
        }
    
        _super($item, container)
      },
      onDrag: function ($item, position) {
        $item.css({
          left: position.left - adjustment.left,
          top: position.top - adjustment.top
        })
      }
    });
    
    $("input.filter").on("keyup", function() {
        var self = $(this),
            val  = self.val();
            
        try {
            var regex = new RegExp(val);
            $("ol.cts-source li").each(function() {
                if(!regex.test($(this).text())) {
                    $(this).hide();
                } else {
                    $(this).show();
                }
            });
        } catch (e) {
            $("ol.cts-source li").show();
        }
    });
    
    $("input.transfer-to-source").on("click", function(e) {
        e.preventDefault();
        var target = $("ol.cts-target");
        
        $("ol.cts-source li:visible").each(function() {
            var element = $(this).clone();
            target.append(element);
            $(this).remove();
        });
    });
    
    
    
});