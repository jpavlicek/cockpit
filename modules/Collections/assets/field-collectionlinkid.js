(function(App, riot) {
	App.Utils.populateCollectionlinkId = function (viewObject) {
		var populateEntryCollection = function(entry, field) {
			var searchFor = entry[field.name],
				newValue = [];
			
			viewObject.collectionsInclude[field.options.link].entries.forEach(function (collection, index) {
				if (collection._id == searchFor) {
					for (value in collection) {
						if (value.search('_') == 0) continue;
						
						newValue.push(collection[value]);
					}
			
					entry[field.name] = newValue.join(', ');
				}
			});
		};
		
		viewObject.fields.forEach(function(field, index) {
			if (field.type == 'collectionlinkid') {
				
				if (!viewObject.collectionsInclude) {
					viewObject.collectionsInclude = {};
				}
			
				App.request('/collections/find', {collection:field.options.link}).then(function(data){
					viewObject.collectionsInclude[field.options.link] = data;
					
					viewObject.entries.forEach(function (entry, index) {
						if (entry[field.name]) {
							populateEntryCollection(entry, field);
						}
					});
					
					viewObject.update();
				}.bind(viewObject));
					
			}
		});     
	};
    
    /*
    App.Utils.renderCollection = function(renderer, v, options) {
    };
    */

})(App, riot);