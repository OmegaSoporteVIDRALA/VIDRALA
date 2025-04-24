import { LightningElement, track } from 'lwc';

export default class OmStocksTable extends LightningElement {

    @track tableData = [
        {
            id: '1',
            color: 'M - Musgo',
            material: '16686',
            descripcion: '1117242 M BORD.NOVA 75CL[PF-IC-F-07]',
            mesAno: 'JUL 2023',
            lote: '2028201311',
            exisBloqueadasBot: '0',
            exisLibresBot: 'L',
            exisNoConfPlanta: 'P',
            dash: '---',
            exisLibresPal: '#'
        },
        // Agrega más filas según los datos
    ];
}