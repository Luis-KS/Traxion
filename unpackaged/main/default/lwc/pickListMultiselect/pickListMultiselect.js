import { LightningElement, api, track } from 'lwc';

export default class PickListMultiselect extends LightningElement {
  @api label = ""; //Name of the dropDown
  @api maxselected = 2; //Max selected item display
  @api options; // List of items to display
  @api showfilterinput = false; //show filterbutton
  @api showrefreshbutton = false; //show the refresh button
  @api showselectallbutton = false; //show the select all button
  @api showclearbutton = false; //show the clear button
  @api comboplaceholder = "Selecciona una Opción";
  @api defaultselectedvalues = [];
  @api rerenderselected;

  @track _initializationCompleted = false;
  @track _selectedItems = "Selecciona una Opción";
  @track _filterValue;
  @track _mOptions;

  constructor() {
    super();
    this._filterValue = "";
  }

  renderedCallback() {
    let self = this;
    if (!this._initializationCompleted) {
      this.template
        .querySelector(".ms-input")
        .addEventListener("click", function (event) {
          console.log("multipicklist clicked");
          self.onDropDownClick(event.target);
          event.stopPropagation();
        });
      this.template.addEventListener("click", function (event) {
        console.log("multipicklist-1 clicked");
        event.stopPropagation();
      });
      document.addEventListener("click", function (event) {
        console.log("document clicked");
        self.closeAllDropDown();
      });
      this._initializationCompleted = true;
      this.setPickListName();

      console.log("-------otro componente: " + JSON.stringify(this.defaultselectedvalues));
      console.log('this.rerenderselected: ' + this.rerenderselected);
      if (this.defaultselectedvalues && this.defaultselectedvalues.length > 0  && this.rerenderselected) {
        const simulatedEvents = this.defaultselectedvalues.map((item) => ({
          detail: {
            item: {
              key: item.key,
              value: item.value
            },
            selected: true
          }
        }));
        console.log(JSON.stringify(simulatedEvents));
        this.handleItemSelected(simulatedEvents);
      }
    }
  }

  handleItemSelected(event) {
    console.log('otro componente');
    console.log(event.length);
    console.log(JSON.parse(JSON.stringify(event)));
    this._mOptions.forEach(function (eachItem) {
      if(event.length > 0 && event.length != undefined) {
        event.forEach(item => {
          if (eachItem.key == item.detail.item.key) {
            eachItem.selected = item.detail.selected;
            return;
          }
        })
      } else {
        if (eachItem.key == event.detail.item.key) {
          eachItem.selected = event.detail.selected;
          return;
        }
      }
    });
    this.setPickListName();
    this.onItemSelected();
  }

  filterDropDownValues(event) {
    this._filterValue = event.target.value;
    this.updateListItems(this._filterValue);
  }

  closeAllDropDown() {
    Array.from(this.template.querySelectorAll(".ms-picklist-dropdown")).forEach(
      function (node) {
        node.classList.remove("slds-is-open");
      }
    );
  }

  onDropDownClick(dropDownDiv) {
    let classList = Array.from(
      this.template.querySelectorAll(".ms-picklist-dropdown")
    );
    if (!classList.includes("slds-is-open")) {
      this.closeAllDropDown();
      Array.from(
        this.template.querySelectorAll(".ms-picklist-dropdown")
      ).forEach(function (node) {
        node.classList.add("slds-is-open");
      });
    } else {
      this.closeAllDropDown();
    }
  }

  @api onRefreshClick(event) {
    console.log('refresh');
    this._filterValue = "";
    this.initArray(this);
    this.updateListItems("");
    this.onItemSelected();
  }

  @api onSelectAll() {
    console.log('selectAll');
    this._filterValue = "";
    this.updateListItems("");
    this._mOptions.forEach(option => {
      option.selected = true;
    });
    Array.from(this.template.querySelectorAll('c-pick-list-item')).forEach(node => {
      node.selected = true;
    });
    this.setPickListName();
    this.onItemSelected();
  }

  handleSelectAll(event) {
    const isChecked = event.target.checked;
    isChecked ? this.onSelectAll() : this.onRefreshClick();
  }

  onClearClick(event) {
    this._filterValue = "";
    this.updateListItems("");
  }

  connectedCallback() {
    this.initArray(this);
    console.log('CONNECTED');
  }

  initArray(context) {
    context._mOptions = new Array();
    context.options.forEach(function (eachItem) {
      context._mOptions.push(JSON.parse(JSON.stringify(eachItem)));
    });
  }

  updateListItems(inputText) {
    Array.from(this.template.querySelectorAll("c-pick-list-item")).forEach(
      function (node) {
        if (!inputText) {
          node.style.display = "block";
        } else if (
          node.item.value
            .toString()
            .toLowerCase()
            .indexOf(inputText.toString().trim().toLowerCase()) != -1
        ) {
          node.style.display = "block";
        } else {
          node.style.display = "none";
        }
      }
    );
    this.setPickListName();
  }

  setPickListName() {
    let selecedItems = this.getSelectedItems();
    let selections = "";
    if (selecedItems.length < 1) {
      selections = this.comboplaceholder;
    } else if (selecedItems.length > this.maxselected) {
      selections = selecedItems.length + " Opciones Seleccionadas";
    } else {
      selecedItems.forEach((option) => {
        selections += option.value + ",";
      });
    }
    this._selectedItems = selections;
  }

  @api
  getSelectedItems() {
    let resArray = new Array();
    this._mOptions.forEach(function (eachItem) {
      if (eachItem.selected) {
        resArray.push(eachItem);
      }
    });
    return resArray;
  }

  onItemSelected() {
    const evt = new CustomEvent("itemselected", {
      detail: this.getSelectedItems(),
    });
    this.dispatchEvent(evt);
  }
}