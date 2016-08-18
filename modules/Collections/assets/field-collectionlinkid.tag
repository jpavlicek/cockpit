<field-collectionlinkId>

    <div class="uk-alert" if="{!opts.link}">
        { App.i18n.get('Collection to link not defined in the field settings') }
    </div>

    <div class="uk-alert uk-alert-danger" if="{opts.link && error}">
        { App.i18n.get('Failed loading collection') } {opts.link}
    </div>

    <div class="uk-alert" if="{opts.link && !collection && !error}">
        <i class="uk-icon-spinner uk-icon-spin"></i> { App.i18n.get('Loading field') }
    </div>

    <div if="{opts.link && collection}">

        <div class="uk-alert" if="{!link}">
            { App.i18n.get('Nothing linked yet') }. <a onclick="{ showDialog }">{ App.i18n.get('Create link to') } { collection.label || opts.link }</a>
        </div>

        <div if="{link}">
            <div class="uk-panel uk-panel-card uk-panel-box">
				
                <div class="uk-grid uk-grid-small uk-text-small" each="{field,idx in fields}" if="{field.name != '_modified'}">
                    <div class="uk-text-bold uk-width-medium-1-5">{ field.label || field.name }</div>
                    <div class="uk-flex-item-1"><raw content="{ App.Utils.renderValue(field.type, entry[field.name]) }"></raw></div>
                </div>

                <div class="uk-panel-box-footer uk-text-small uk-padding-bottom-remove">
                    <a class="uk-margin-small-right" onclick="{ showDialog }"><i class="uk-icon-link"></i> { App.i18n.get('Link item') }</a>
                    <a class="uk-text-danger" onclick="{ removeItem }"><i class="uk-icon-trash-o"></i> { App.i18n.get('Remove') }</a>
                </div>
            </div>

        </div>

    </div>

    <div class="uk-modal">

        <div class="uk-modal-dialog uk-modal-dialog-large">
            <a href="" class="uk-modal-close uk-close"></a>
            <h3>{ collection.label || opts.link }</h3>

            <div class="uk-margin">

                <div class="uk-form-icon uk-form uk-width-1-1 uk-text-muted">

                    <i class="uk-icon-search"></i>
                    <input class="uk-width-1-1 uk-form-large uk-form-blank" type="text" name="txtfilter" placeholder="{ App.i18n.get('Filter items...') }" onchange="{ updatefilter }">

                </div>

            </div>

            <div class="uk-overflow-container">

                <div class="uk-alert" if="{ !entries.length && filter && !loading }">
                    { App.i18n.get('No entries found') }.
                </div>

                <table class="uk-table uk-table-striped uk-margin-top" if="{ entries.length }">
                    <thead>
                        <tr>
                            <th class="uk-text-small" each="{field,idx in fields}">
                                <a class="uk-link-muted { parent.sort[field.name] ? 'uk-text-primary':'' }" onclick="{ parent.updatesort }" data-sort="{ field.name }">

                                    { field.label || field.name }

                                    <span if="{parent.sort[field.name]}" class="uk-icon-long-arrow-{ parent.sort[field.name] == 1 ? 'up':'down'}"></span>
                                </a>
                            </th>
                            <th width="20"></th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr each="{entry,idx in entries}">
                            <td class="uk-text-truncate" each="{field,idy in parent.fields}" if="{ field.name != '_modified' }">
                                <raw content="{ App.Utils.renderValue(field.type, parent.entry[field.name]) }"></raw>
                            </td>
                            <td>{ App.Utils.dateformat( new Date( 1000 * entry._modified )) }</td>
                            <td>
                                <a onclick="{ parent.linkItem }"><i class="uk-icon-link"></i></a>
                            </td>
                        </tr>
                    </tbody>
                </table>

                <div class="uk-alert" if="{ loading }">
                    <i class="uk-icon-spinner uk-icon-spin"></i> {App.i18n.get('Loading...')}.
                </div>

                <div class="uk margin" if="{ loadmore && !loading }">
                    <a class="uk-button uk-width-1-1" onclick="{ load }">
                        { App.i18n.get('Load more...') }
                    </a>
                </div>

            </div>
        </div>
    </div>


    <script>

    var $this = this, modal, collections, _init = function(){

        this.error = this.collection ? false:true;

        this.loadmore   = false;
        this.entry      = false;
        this.entries    = [];
        this.fieldsidx  = {};
        this.fields     = this.collection.fields.filter(function(field){
            $this.fieldsidx[field.name] = field;
            return field.lst;
        });

        this.fields.push({name:'_modified', 'label':App.i18n.get('Modified')});
		
		this.loadEntry(this.link);
		
        this.update();

    }.bind(this);

    this.link       = null;
    this.sort       = {'_created': -1};


    this.$updateValue = function(value, field) {

        if (JSON.stringify(this.reference) !== JSON.stringify(value)) {
            this.link = value;
            this.update();
        }

    }.bind(this);

    this.on('mount', function(){

        if (!opts.link) return;

        modal = UIkit.modal(App.$('.uk-modal', this.root));

        Cockpit.callmodule('collections:collections').then(function(data){
            collections = data.result;
            $this.collection  = collections[opts.link] || null;
            _init();
        });

        App.$(this.txtfilter).on('keydown', function(e){

            if(e.keyCode == 13) {
                e.preventDefault();
                e.stopPropagation();

                $this.updatefilter(e);
                $this.update();
            }
        });
    });

    showDialog(){
        modal.show();
        this.load();
    }

	loadEntry(_id) {		
		return App.callmodule('collections:findOne', [this.collection.name, {'_id': _id}]).then(function(data){
			this.entry = data.result;
			console.log(this);
			this.update();
        }.bind(this));
	}

    linkItem(e) {
        var entry = e.item.entry
        this.entry = entry;

        this.link = entry._id;

        setTimeout(function(){
            modal.hide();
        }, 50);

        this.$setValue(this.link);
    }

    removeItem() {
        this.link = null;
        this.$setValue(this.link);
    }

    removeListItem(e) {
        this.link.splice(e.item.index, 1);
        this.$setValue(this.link);
    }

    load() {

        var limit = 50;

        var options = { sort:this.sort };

        if (this.filter) {
            options.filter = this.filter;
        } else {
            if (opts.filter) {
                options.filter = opts.filter;
            }
        }

        if (!this.collection.sortable) {
            options.limit = limit;
            options.skip  = this.entries.length || 0;
        }

        this.loading = true;

        return App.callmodule('collections:find', [this.collection.name, options]).then(function(data){
            this.entries = this.entries.concat(data.result);
            App.Utils.populateCollectionlinkId(this);

            this.ready    = true;
            this.loadmore = data.result.length && data.result.length == limit;

            this.loading = false;

            this.update();

        }.bind(this))
    }

    updatefilter(e) {

        var load = this.filter ? true:false;

        this.filter = null;

        if (this.txtfilter.value) {

            var filter       = this.txtfilter.value,
                criterias    = [],
                allowedtypes = ['text','longtext','boolean','select','html','wysiwyg','markdown','code'],
                criteria;

            if (App.Utils.str2json('{'+filter+'}')) {

                filter = App.Utils.str2json('{'+filter+'}');

                var key, field;

                for (key in filter) {

                    field = this.fieldsidx[key] || {};

                    if (allowedtypes.indexOf(field.type) !== -1) {

                        criteria = {};
                        criteria[key] = field.type == 'boolean' ? filter[key]: {'$regex':filter[key]};
                        criterias.push(criteria);
                    }
                }

                if (criterias.length) {
                    this.filter = {'$and':criterias};
                }

            } else {

                this.collection.fields.forEach(function(field){

                   if (field.type != 'boolean' && allowedtypes.indexOf(field.type) !== -1) {
                       criteria = {};
                       criteria[field.name] = {'$regex':filter};
                       criterias.push(criteria);
                   }

                });

                if (criterias.length) {
                    this.filter = {'$or':criterias};
                }
            }

        }

        if (this.filter || load) {

            if (opts.filter) {
                
                Object.keys(opts.filter).forEach(function(k) {
                    switch(k) {
                        case '$and':
                        case '$or':
                            if ($this.filter[k]) {
                                this.filter[k] = this.filter[k].concat(opts.filter[k]);
                            } else {
                                $this.filter[k] = opts.filter[k];
                            }
                            break;
                        default:
                            $this.filter[k] = opts.filter[k];
                    }
                });
                
                this.filter = opts.filter;
            }

            this.entries = [];
            this.loading = true;
            this.load();
        }

        return false;
    }

    updatesort(e, field) {

        field = e.target.getAttribute('data-sort');

        if (!field) {
            return;
        }

        if (!this.sort[field]) {
            this.sort        = {};
            this.sort[field] = 1;
        } else {
            this.sort[field] = this.sort[field] == 1 ? -1:1;
        }

        this.entries = [];

        this.load();
    }

    updateorder() {

        var items = [];

        App.$($this.root).css('height', App.$($this.root).height());

        App.$('.uk-sortable', $this.root).children().each(function(){
            items.push($this.link[Number(this.getAttribute('data-idx'))]);
        });

        $this.link = [];
        $this.update();

        setTimeout(function() {
            $this.link = items;
            $this.$setValue($this.link);
            $this.update();

            setTimeout(function(){
                $this.root.style.height = '';
            }, 30)
        }, 10);
    }

    </script>

</field-collectionlinkId>
