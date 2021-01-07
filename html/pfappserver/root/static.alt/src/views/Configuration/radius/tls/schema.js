import store from '@/store'
import i18n from '@/utils/locale'
import yup from '@/utils/yup'

yup.addMethod(yup.string, 'radiusTlsIdNotExistsExcept', function (exceptId = '', message) {
  return this.test({
    name: 'radiusTlsIdNotExistsExcept',
    message: message || i18n.t('Identifier exists.'),
    test: (value) => {
      if (!value || value.toLowerCase() === exceptId.toLowerCase()) return true
      return store.dispatch('config/getRadiusTlss').then(response => {
        return response.filter(tls => tls.id.toLowerCase() === value.toLowerCase()).length === 0
      }).catch(() => {
        return true
      })
    }
  })
})

export default (props) => {
  const {
    id,
    isNew,
    isClone
  } = props

  return yup.object().shape({
    id: yup.string()
      .nullable()
      .required(i18n.t('Identifier required.'))
      .radiusTlsIdNotExistsExcept((!isNew && !isClone) ? id : undefined, i18n.t('Identifier exists.'))
  })
}
