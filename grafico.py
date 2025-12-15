import altair as alt
import pandas as pd

# Convert 'Data' column to datetime
df['Data'] = pd.to_datetime(df['Data'])

# Create the first line chart for 'Caixa ao fim do dia(R$)'
chart_saldo = alt.Chart(df).mark_line(point=True).encode(
	x=alt.X('Data', title='Data'),
	y=alt.Y('Caixa ao fim do dia(R$)', title='Saldo de Caixa (R$)'),
	tooltip=['Data', 'Caixa ao fim do dia(R$)']
).properties(
	title='Evolução do Saldo de Caixa ao Longo do Tempo'
).interactive()

# Create the second line chart for 'Saldo do dia (R$)'
chart_saldo_dia = alt.Chart(df).mark_bar().encode(
	x=alt.X('Data', title='Data'),
	y=alt.Y('Saldo do dia (R$)', title='Saldo do Dia (R$)'),
	tooltip=['Data', 'Saldo do dia (R$)']
).properties(
	title='Variação Diária do Saldo'
).interactive()

# Save the charts as JSON files
chart_saldo.save('evolucao_saldo_caixa.json')
chart_saldo_dia.save('variacao_diaria_saldo.json')

print("Gráficos gerados com sucesso!")