let preveiwContainer = document.querySelector('.whisky-preview');
let previewBox = preveiwContainer.querySelectorAll('.preview');

document.querySelectorAll('.whisky-container .whisky').forEach(product =>{
  product.onclick = () =>{
    preveiwContainer.style.display = 'flex';
    let name = product.getAttribute('data-name');
    previewBox.forEach(preview =>{
      let target = preview.getAttribute('data-target');
      if(name == target){
        preview.classList.add('active');
      }
    });
  };
});

document.querySelectorAll('.whisky-container .whisky-special').forEach(product =>{
  product.onclick = () =>{
    preveiwContainer.style.display = 'flex';
    let name = product.getAttribute('data-name');
    previewBox.forEach(preview =>{
      let target = preview.getAttribute('data-target');
      if(name == target){
        preview.classList.add('active');
      }
    });
  };
});

previewBox.forEach(close =>{
  close.querySelector('.fa-xmark').onclick = () =>{
    close.classList.remove('active');
    preveiwContainer.style.display = 'none';
  };
});